<#
.SYNOPSIS
    Generic PostgreSQL health-check report generator (cluster + database).
    Windows PowerShell port of generate_reports.sh (same behavior, same env
    var names, same report.conf format).

.DESCRIPTION
    No environment-specific defaults: every service list, label, timeout and
    dbname override is passed in via parameters or env vars.

    The database used for "database" kind reports is picked per service, in
    this order:
      1. The config file's dbname column for that service (-ConfigFile).
      2. -DefaultDbname, if given (applies to every service without a
         config-file entry).
      3. Auto-detected by connecting to the service (its pg_service.conf
         default database) and picking, in order of preference: the
         database with the highest pg_stat_statements load if that
         extension is installed, otherwise the largest database by size.

    Layout expected (this repo's reports/ + sql/ split):
      reports\generate_reports.ps1  <- this file
      reports\report_cluster.sql    <- found next to this script, always
      reports\report_database.sql   <- found next to this script, always
      reports\normalize_md.py       <- found via -NormalizeScript, see below
      sql\*.sql                     <- fragment library \ir'd by
                                        report_*.sql, found via -ScriptsDir

    report_cluster.sql/report_database.sql (plain psql scripts, unchanged
    from the Bash version) \ir a chain of fragments; this script invokes
    them with the working directory set to its own folder and a bare
    relative filename, so psql's \ir tracks "." as their base directory,
    then passes -v sql_dir=<-ScriptsDir> so their leading `\cd :sql_dir`
    retargets every subsequent \ir at the fragment library in sql\.

    If no service is given (-Service, positional, and REPORT_SERVICES also
    unset), the services listed in the config file (-ConfigFile, see below)
    are used instead, in file order. It's an error to omit services with no
    config file to fall back to.

    -Localhost ignores services entirely (CLI args, REPORT_SERVICES, and
    the config file's service list) and connects to the local PostgreSQL
    instead (no service=/host=, just whatever psql's own defaults resolve
    to). The machine's hostname (COMPUTERNAME) is used in place of the
    service name in the output filename; -DefaultDbname and dbname
    auto-detection still apply for "database" kind reports (the config
    file's per-service label/dbname/timeout columns do not, since there's
    no service to look them up by).

    Config file (-ConfigFile / REPORT_CONFIG_FILE), lines "service label
    dbname stmt_timeout total_timeout [kind]", used for:
      - label: renames the output file (label = service when a service
        has no entry).
      - dbname: picks the database "database" kind reports connect to for
        that service (see the priority order above).
      - stmt_timeout/total_timeout: override -StmtTimeout/-TotalTimeout for
        that service. kind defaults to "*" (both); give the same service
        two lines with different kinds for different cluster vs. database
        timeouts.
    Also doubles as the service list when none is given on the command
    line (services used in file order). Use "-" (or omit trailing columns)
    to skip just one column while still setting others on the same line.
    Default: $HOME\pg_scripts\reports\report.conf if it exists, otherwise
    nothing is loaded/overridden.

    Output: <OutDir>\YYYY-MM-DD\YYYY-MM-DD_<label>_<kind>.md

.PARAMETER Service
    pg_service.conf service name(s), positional (e.g. `prd_eu prd_us`). If
    omitted, falls back to REPORT_SERVICES, then the config file's service
    list (see .DESCRIPTION); ignored entirely under -Localhost.

.PARAMETER ScriptsDir
    Dir with the sql\ fragment library (variables.sql, internal.sql, ...).
    Env: REPORT_SCRIPTS_DIR. Default: $HOME\pg_scripts\sql.

.PARAMETER NormalizeScript
    Path to normalize_md.py, or a directory containing it. Env:
    REPORT_NORMALIZE_SCRIPT. Default: $HOME\pg_scripts\reports.

.PARAMETER OutDir
    Base output directory. Env: REPORT_OUT_DIR. Default: $HOME\reports.

.PARAMETER Kinds
    Report kind(s): cluster, database, or both (default). Comma-separated
    values work unquoted (PowerShell's own array syntax) or quoted as one
    string. Env: REPORT_KINDS.

.PARAMETER ConfigFile
    Path to the unified config file (see .DESCRIPTION). Env:
    REPORT_CONFIG_FILE. Default: $HOME\pg_scripts\reports\report.conf if
    it exists, otherwise nothing is loaded/overridden.

.PARAMETER DefaultDbname
    Fallback database for "database" kind reports, for any service without
    a config-file dbname (see the priority order in .DESCRIPTION). Env:
    REPORT_DEFAULT_DBNAME. No default — omit it to auto-detect instead.

.PARAMETER StmtTimeout
    Default statement_timeout. Env: REPORT_STMT_TIMEOUT. Default: 300s.

.PARAMETER TotalTimeout
    Default per-report wall-clock timeout, in seconds. Env:
    REPORT_TOTAL_TIMEOUT. Default: 600.

.PARAMETER Localhost
    Ignore all services and connect to the local PostgreSQL instead (see
    .DESCRIPTION). The machine's hostname replaces the service name in the
    output filename.

.NOTES
    Requires pwsh (PowerShell 7+) — uses ProcessStartInfo.ArgumentList,
    not available in Windows PowerShell 5.1. Also requires psql and a
    python3 (or python) interpreter in PATH.

    Windows note: by default, Windows blocks running unsigned .ps1 scripts.
    Run this with:
        pwsh -ExecutionPolicy Bypass -File .\generate_reports.ps1 ...
    or, in an already-open session:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.EXAMPLE
    .\generate_reports.ps1 prd_eu prd_us

.EXAMPLE
    .\generate_reports.ps1 -Kinds cluster -DefaultDbname postgres -Localhost
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Service = @(),

    [Alias('d')][string]$ScriptsDir,
    [Alias('m')][string]$NormalizeScript,
    [Alias('o')][string]$OutDir,
    [Alias('k')][string[]]$Kinds,
    [Alias('c')][string]$ConfigFile,
    [Alias('n')][string]$DefaultDbname,
    [string]$StmtTimeout,
    [int]$TotalTimeout = 0,
    [switch]$Localhost
)

$ErrorActionPreference = 'Stop'

$SelfDir = $PSScriptRoot

# ---------------------------------------------------------------------------
# Defaults (CLI param > REPORT_* env var > hard-coded default), mirroring
# generate_reports.sh's own defaults.
# ---------------------------------------------------------------------------

if (-not $ScriptsDir) {
    $ScriptsDir = if ($env:REPORT_SCRIPTS_DIR) { $env:REPORT_SCRIPTS_DIR } else { Join-Path $HOME 'pg_scripts\sql' }
}
if (-not $NormalizeScript) {
    $NormalizeScript = if ($env:REPORT_NORMALIZE_SCRIPT) { $env:REPORT_NORMALIZE_SCRIPT } else { Join-Path $HOME 'pg_scripts\reports' }
}
if (-not $OutDir) {
    $OutDir = if ($env:REPORT_OUT_DIR) { $env:REPORT_OUT_DIR } else { Join-Path $HOME 'reports' }
}
if (-not $Kinds -or $Kinds.Count -eq 0) {
    # -Kinds is [string[]] (not [string]) specifically so an unquoted
    # comma-separated value on the command line — PowerShell's own array-
    # construction syntax, e.g. `-Kinds cluster,database` — binds directly
    # without any string/array coercion ambiguity.
    $Kinds = if ($env:REPORT_KINDS) { @($env:REPORT_KINDS) } else { @('cluster', 'database') }
}
$ConfigFileIsDefault = $true
if ($ConfigFile) {
    $ConfigFileIsDefault = $false
} elseif ($env:REPORT_CONFIG_FILE) {
    $ConfigFile = $env:REPORT_CONFIG_FILE
    $ConfigFileIsDefault = $false
}
if (-not $DefaultDbname) {
    $DefaultDbname = $env:REPORT_DEFAULT_DBNAME
}
if (-not $StmtTimeout) {
    $StmtTimeout = if ($env:REPORT_STMT_TIMEOUT) { $env:REPORT_STMT_TIMEOUT } else { '300s' }
}
if ($TotalTimeout -le 0) {
    $TotalTimeout = if ($env:REPORT_TOTAL_TIMEOUT) { [int]$env:REPORT_TOTAL_TIMEOUT } else { 600 }
}

function Resolve-AbsolutePath {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path (Get-Location).Path $Path)
}

# ---------------------------------------------------------------------------
# Python interpreter: Windows Python installs are usually just "python", not
# "python3" (unlike Linux/macOS) — try python3 first, fall back to python.
# ---------------------------------------------------------------------------

$PythonCmd = $null
foreach ($candidate in @('python3', 'python')) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) { $PythonCmd = $candidate; break }
}
if (-not $PythonCmd) {
    Write-Host 'Neither python3 nor python found in PATH. normalize_md.py needs a Python 3 interpreter.'
    exit 2
}

# ---------------------------------------------------------------------------
# Config file + service list resolution (skipped entirely under -Localhost).
# ---------------------------------------------------------------------------

$Label = @{}
$Dbname = @{}
$OvrStmt = @{}
$OvrTotal = @{}

if ($Localhost) {
    if ($Service.Count -gt 0 -or $env:REPORT_SERVICES) {
        Write-Warning '-Localhost ignores services given on the command line / REPORT_SERVICES'
    }
    $HostnameLabel = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { (& hostname).Trim() }
    $Services = @($HostnameLabel)
} else {
    if (-not $ConfigFile) {
        $ConfigFile = Join-Path $HOME 'pg_scripts\reports\report.conf'
        $ConfigFileIsDefault = $true
    }
    $ConfigFile = Resolve-AbsolutePath $ConfigFile

    $ConfigSeen = @{}
    $ServiceOrder = [System.Collections.Generic.List[string]]::new()

    if (Test-Path -PathType Leaf $ConfigFile) {
        foreach ($rawLine in Get-Content -Path $ConfigFile) {
            $line = $rawLine.Trim()
            if (-not $line -or $line.StartsWith('#')) { continue }
            $fields = $line -split '\s+'
            $svc = $fields[0]
            # Named distinctly from the $Label/$Dbname hashtables below — Power
            # Shell variable names are case-insensitive, so "$label"/"$Label"
            # would otherwise be the same variable and each line's assignment
            # would clobber the whole hashtable built up so far.
            $fieldLabel = if ($fields.Length -gt 1) { $fields[1] } else { $null }
            $fieldDbname = if ($fields.Length -gt 2) { $fields[2] } else { $null }
            $stmt = if ($fields.Length -gt 3) { $fields[3] } else { $null }
            $total = if ($fields.Length -gt 4) { $fields[4] } else { $null }
            $kind = if ($fields.Length -gt 5) { $fields[5] } else { $null }
            if (-not $kind) { $kind = '*' }

            if (-not $ConfigSeen.ContainsKey($svc)) {
                $ServiceOrder.Add($svc)
                $ConfigSeen[$svc] = $true
            }
            if ($fieldLabel -and $fieldLabel -ne '-') { $Label[$svc] = $fieldLabel }
            if ($fieldDbname -and $fieldDbname -ne '-') { $Dbname[$svc] = $fieldDbname }
            if ($stmt -and $stmt -ne '-') { $OvrStmt["${svc}:${kind}"] = $stmt }
            if ($total -and $total -ne '-') { $OvrTotal["${svc}:${kind}"] = $total }
        }
    } elseif (-not $ConfigFileIsDefault) {
        Write-Host "Config file not found: $ConfigFile"
        exit 2
    }

    $Services = @($Service)
    if ($Services.Count -eq 0 -and $env:REPORT_SERVICES) {
        $Services = @($env:REPORT_SERVICES -split '[,\s]+' | Where-Object { $_ })
    }
    if ($Services.Count -eq 0 -and $ServiceOrder.Count -gt 0) {
        $Services = @($ServiceOrder)
        Write-Warning "No service given on the command line — using the $($Services.Count) service(s) listed in $ConfigFile"
    }
    if ($Services.Count -eq 0) {
        Write-Host "No service given. Pass one or more pg_service.conf service names as arguments, set REPORT_SERVICES, or list them in the config file (-ConfigFile, default `$HOME\pg_scripts\reports\report.conf), or use -Localhost."
        exit 2
    }
}

$KindList = @($Kinds -split ',' | Where-Object { $_ })
if ($KindList.Count -eq 0) {
    Write-Host 'No report kind given via -Kinds/REPORT_KINDS.'
    exit 2
}

$ScriptsDir = Resolve-AbsolutePath $ScriptsDir
$OutDir = Resolve-AbsolutePath $OutDir
$NormalizeScript = Resolve-AbsolutePath $NormalizeScript

if (-not (Test-Path -PathType Container $ScriptsDir)) {
    Write-Host "-ScriptsDir '$ScriptsDir' is not a directory. Point -ScriptsDir (or REPORT_SCRIPTS_DIR) at the sql\ fragment library."
    exit 2
}

if ((($KindList -contains 'cluster') -and -not (Test-Path (Join-Path $SelfDir 'report_cluster.sql'))) -or
    (($KindList -contains 'database') -and -not (Test-Path (Join-Path $SelfDir 'report_database.sql')))) {
    Write-Host "report_*.sql not found next to this script ($SelfDir). generate_reports.ps1 must stay alongside report_cluster.sql/report_database.sql."
    exit 2
}

if (Test-Path -PathType Container $NormalizeScript) {
    $NormalizeScript = Join-Path $NormalizeScript 'normalize_md.py'
}
if (-not (Test-Path -PathType Leaf $NormalizeScript)) {
    Write-Host "normalize_md.py not found at '$NormalizeScript'. Point -NormalizeScript (or REPORT_NORMALIZE_SCRIPT) at it."
    exit 2
}

# ---------------------------------------------------------------------------
# Locates the pg_service.conf file the same way libpq does on Windows
# (https://www.postgresql.org/docs/current/libpq-pgservice.html):
#   1. $env:PGSERVICEFILE
#   2. $env:PGSYSCONFDIR\pg_service.conf
#   3. <pg_config --sysconfdir>\pg_service.conf
#   4. %APPDATA%\postgresql\.pg_service.conf   (per-user file; note it keeps
#      the leading dot even on Windows, just under a "postgresql" folder)
# Purely advisory — gives a clearer pre-flight warning than psql's own
# connection error when a requested service is missing. Non-fatal either
# way: psql does its own resolution when it actually connects.
# ---------------------------------------------------------------------------

function Resolve-PgServiceFile {
    if ($env:PGSERVICEFILE -and (Test-Path $env:PGSERVICEFILE)) {
        return $env:PGSERVICEFILE
    }
    if ($env:PGSYSCONFDIR) {
        $candidate = Join-Path $env:PGSYSCONFDIR 'pg_service.conf'
        if (Test-Path $candidate) { return $candidate }
    }
    if (Get-Command pg_config -ErrorAction SilentlyContinue) {
        $sysconfdir = (& pg_config --sysconfdir 2>$null)
        if ($sysconfdir) {
            $candidate = Join-Path $sysconfdir.Trim() 'pg_service.conf'
            if (Test-Path $candidate) { return $candidate }
        }
    }
    if ($env:APPDATA) {
        $candidate = Join-Path $env:APPDATA 'postgresql\.pg_service.conf'
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Auto-detects a database for "database" kind reports when neither the
# config file nor -DefaultDbname picked one for this service (lowest
# priority, see the header comment): connects (using the same conn string
# the caller is about to use, minus any dbname) to whatever database that
# resolves to by default, and prefers the busiest database by
# pg_stat_statements load, if that extension is installed there, otherwise
# the largest by size. Returns the resolved dbname, or '' on failure.
# ---------------------------------------------------------------------------

function Resolve-AutoDbname {
    param([string]$ConnBase)

    $sql = @'
SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements')
  THEN (
    SELECT d.datname
    FROM pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
    WHERE d.datistemplate IS FALSE
    GROUP BY d.datname
    ORDER BY sum(s.total_plan_time) + sum(s.total_exec_time) DESC
    LIMIT 1
  )
  ELSE (
    SELECT datname FROM pg_database
    WHERE datistemplate IS FALSE
    ORDER BY pg_database_size(datname) DESC
    LIMIT 1
  )
END;
'@

    # File-based redirection + WaitForExit(ms)-then-read (same pattern as
    # Invoke-ReportPsql below, see its comment): reading via .StandardOutput
    # would block indefinitely on a truly stuck connection that never closes
    # its output, defeating the 30s timeout entirely.
    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    try {
        $psqlArgs = @($ConnBase, '-X', '-q', '-t', '-A', '-c', $sql)
        $proc = Start-Process -FilePath psql -ArgumentList $psqlArgs `
            -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr -NoNewWindow -PassThru

        $finished = $proc.WaitForExit(30000)
        if (-not $finished) {
            try { $proc.Kill($true) } catch {}
            $proc.WaitForExit()
            return ''
        }
        if ($proc.ExitCode -ne 0) { return '' }
        $stdout = Get-Content -Raw -Path $tmpOut -ErrorAction SilentlyContinue
        if (-not $stdout) { return '' }
        return $stdout.Trim()
    } catch {
        return ''
    } finally {
        Remove-Item -ErrorAction SilentlyContinue $tmpOut, $tmpErr
    }
}

# ---------------------------------------------------------------------------
# Runs report_<kind>.sql through psql with a wall-clock timeout, redirecting
# stdout/stderr to temp files (file-based redirection avoids the classic
# .NET Process pipe-deadlock risk on large output — no fixed pipe buffer to
# fill, unlike in-memory stream redirection).
# ---------------------------------------------------------------------------

function Invoke-ReportPsql {
    param(
        [string]$Conn,
        [string]$SqlDir,
        [string]$Stmt,
        [string]$ReportFile,
        [int]$TimeoutSec
    )

    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    try {
        $psqlArgs = @(
            $Conn, '-X', '-q', '-v', "sql_dir=$SqlDir",
            '-c', "SET statement_timeout='$Stmt'; SET lock_timeout='3s';",
            '-f', $ReportFile
        )
        $proc = Start-Process -FilePath psql -ArgumentList $psqlArgs -WorkingDirectory $SelfDir `
            -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr -NoNewWindow -PassThru

        $finished = $proc.WaitForExit($TimeoutSec * 1000)
        $timedOut = -not $finished
        if ($timedOut) {
            # Kill(true) (.NET Core 3+) terminates the whole process tree, not
            # just this PID — psql itself is a single process, but this is
            # cheap insurance against anything it might spawn.
            try { $proc.Kill($true) } catch {}
            $proc.WaitForExit()
        }

        [PSCustomObject]@{
            ExitCode = if ($timedOut) { -1 } else { $proc.ExitCode }
            TimedOut = $timedOut
            StdOut   = (Get-Content -Raw -Path $tmpOut -ErrorAction SilentlyContinue)
            StdErr   = (Get-Content -Raw -Path $tmpErr -ErrorAction SilentlyContinue)
        }
    } finally {
        Remove-Item -ErrorAction SilentlyContinue $tmpOut, $tmpErr
    }
}

if (-not $Localhost) {
    $PgServiceFile = Resolve-PgServiceFile
    if ($PgServiceFile) {
        foreach ($svc in $Services) {
            $pattern = '^\[' + [regex]::Escape($svc) + '\]'
            $found = Select-String -Path $PgServiceFile -Pattern $pattern -Quiet
            if (-not $found) {
                Write-Warning "service '$svc' not found in $PgServiceFile — will still try, psql may resolve it differently"
            }
        }
    } else {
        Write-Warning 'no pg_service.conf found (checked $env:PGSERVICEFILE, $env:PGSYSCONFDIR, ''pg_config --sysconfdir'', %APPDATA%\postgresql\.pg_service.conf) — services will be validated by psql itself'
    }
}

$Date = Get-Date -Format 'yyyy-MM-dd'
$Out = Join-Path $OutDir $Date
New-Item -ItemType Directory -Path $Out -Force | Out-Null

$AutoDbnameCache = @{}
$fail = $false

foreach ($svc in $Services) {
    # svcLabel, not "label" — PowerShell variable names are case-insensitive,
    # so "$label" would be the same variable as the $Label hashtable above.
    $svcLabel = if ($Label.ContainsKey($svc)) { $Label[$svc] } else { $svc }

    foreach ($kind in $KindList) {
        # Wildcard ("*" kind) override applies first, then the exact-kind
        # override on top of it — stmt and total are resolved independently,
        # so a config line can override just one of the two.
        $stmt = $StmtTimeout
        $total = $TotalTimeout
        if ($OvrStmt.ContainsKey("${svc}:*")) { $stmt = $OvrStmt["${svc}:*"] }
        if ($OvrStmt.ContainsKey("${svc}:${kind}")) { $stmt = $OvrStmt["${svc}:${kind}"] }
        if ($OvrTotal.ContainsKey("${svc}:*")) { $total = [int]$OvrTotal["${svc}:*"] }
        if ($OvrTotal.ContainsKey("${svc}:${kind}")) { $total = [int]$OvrTotal["${svc}:${kind}"] }

        $f = Join-Path $Out "${Date}_${svcLabel}_${kind}.md"

        if ($Localhost) {
            $conn = 'connect_timeout=60'
        } else {
            $conn = "service=$svc connect_timeout=60"
        }

        if ($kind -eq 'database') {
            # svcDbname, not "dbname" — same case-insensitivity reason as
            # $svcLabel above ($Dbname is the hashtable).
            $svcDbname = if ($Dbname.ContainsKey($svc)) { $Dbname[$svc] } else { '' }
            if (-not $svcDbname) { $svcDbname = $DefaultDbname }
            if (-not $svcDbname) {
                if (-not $AutoDbnameCache.ContainsKey($svc)) {
                    $AutoDbnameCache[$svc] = Resolve-AutoDbname -ConnBase $conn
                }
                $svcDbname = $AutoDbnameCache[$svc]
                if (-not $svcDbname) {
                    Write-Warning "could not auto-detect a database for $svc — falling back to this connection's own default database"
                }
            }
            if ($svcDbname) { $conn = "$conn dbname=$svcDbname" }
        }

        $reportSql = "report_$kind.sql"
        if (-not (Test-Path (Join-Path $SelfDir $reportSql))) {
            Write-Host "SKIP  $svc $kind (report_$kind.sql not found in $SelfDir)"
            $fail = $true
            continue
        }

        $result = Invoke-ReportPsql -Conn $conn -SqlDir $ScriptsDir -Stmt $stmt -ReportFile $reportSql -TimeoutSec $total

        # Report includes do \set QUIET off, so psql echoes \timing/\pset
        # feedback to stdout — filtered out here, same lines the Bash
        # version's grep -v drops.
        $rawLines = if ($result.StdOut) { $result.StdOut -split "`r?`n" } else { @() }
        $filtered = $rawLines | Where-Object {
            $_ -notmatch '^(Timing is|Expanded display is|Null display is|Border style is|Pager usage is|Output format is|Tuples only is|Footer is|Title is)'
        }
        $filtered | & $PythonCmd $NormalizeScript | Out-File -FilePath $f -Encoding utf8NoBOM
        $normalizeExit = $LASTEXITCODE

        $success = (-not $result.TimedOut) -and ($result.ExitCode -eq 0) -and ($normalizeExit -eq 0)
        # @(...) forces an array even when only one non-empty line survives the
        # filter — without it, PowerShell unwraps a single pipeline result to a
        # bare string, and [0] on a string indexes its first *character*, not
        # the first line.
        $errFirstLine = if ($result.StdErr) { @($result.StdErr -split "`r?`n" | Where-Object { $_ })[0] } else { $null }
        if ($result.TimedOut) { $errFirstLine = "timed out after ${total}s" }

        if ($success -and (Test-Path $f) -and (Get-Item $f).Length -gt 0) {
            Write-Host "OK    $svc $kind -> $f"
        } elseif ($success) {
            Write-Host "EMPTY $svc $kind ($errFirstLine)"
            Remove-Item -ErrorAction SilentlyContinue $f
            $fail = $true
        } else {
            Write-Host "FAIL  $svc $kind ($errFirstLine)"
            Remove-Item -ErrorAction SilentlyContinue $f
            $fail = $true
        }
    }
}

if ($fail) { exit 1 } else { exit 0 }

