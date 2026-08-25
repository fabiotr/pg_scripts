<#
.SYNOPSIS
    Downloads PostgreSQL log files from an RDS instance via the AWS CLI, filtered by a minimum date.
    Windows PowerShell port of download_rds_logs.sh (same behavior, same env var names).

.DESCRIPTION
    Requirements: AWS CLI (aws.exe) installed and configured (credentials/region).
    No jq needed: PowerShell's built-in ConvertFrom-Json replaces it entirely, so
    (unlike the bash version) there is no separate "no jq" fallback path here.

    Windows note: by default, Windows blocks running unsigned .ps1 scripts.
    Run this with:
        powershell -ExecutionPolicy Bypass -File .\postgres_log_download_from_aws_rds.ps1
    or, in an already-open session:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.NOTES
    Usage:
        .\postgres_log_download_from_aws_rds.ps1
        (set the environment variables below to skip the prompts, e.g.:
         $env:DAYS_BEFORE = '3'; .\postgres_log_download_from_aws_rds.ps1)
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------

# Base destination directory for downloaded logs (the chosen service/instance
# name is appended to this path, e.g.: C:\PostgreSQLLogs\prd_eu)
$DestDirBase = if ($env:DEST_DIR_BASE) { $env:DEST_DIR_BASE } else { 'C:\PostgreSQLLogs' }

# Default number of days back used for the logs' minimum date
# (asked interactively on every run, unless DAYS_BEFORE is already set)
$DefaultDaysBefore = 2

# AWS region (optional; if empty, uses the aws cli's default configuration)
$AwsRegion = $env:AWS_REGION

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "Error: aws cli not found in PATH."
    exit 1
}

# Runs an aws cli command and returns the parsed JSON output. Throws (which,
# uncaught, stops the whole script - the PowerShell equivalent of bash's
# `set -e`) if the aws cli exits non-zero; aws's own error text still prints
# straight to the console since stderr isn't redirected here.
function Invoke-AwsJson {
    param([string[]]$ArgumentList)
    $stdoutLines = & aws @ArgumentList --output json
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "aws $($ArgumentList -join ' ') failed with exit code $exitCode."
    }
    $joined = ($stdoutLines -join "`n")
    if ([string]::IsNullOrWhiteSpace($joined)) {
        return $null
    }
    return $joined | ConvertFrom-Json
}

# ---------------------------------------------------------------------------
# Locates the pg_service file, following libpq's precedence order on Windows:
#   1) PGSERVICEFILE environment variable
#   2) %APPDATA%\postgresql\.pg_service.conf
#   3) <pg_config --sysconfdir>\pg_service.conf
# ---------------------------------------------------------------------------

$PgServiceFile = $null

if ($env:PGSERVICEFILE -and (Test-Path $env:PGSERVICEFILE)) {
    $PgServiceFile = $env:PGSERVICEFILE
} elseif ($env:APPDATA -and (Test-Path (Join-Path $env:APPDATA 'postgresql\.pg_service.conf'))) {
    $PgServiceFile = Join-Path $env:APPDATA 'postgresql\.pg_service.conf'
} elseif (Get-Command pg_config -ErrorAction SilentlyContinue) {
    $sysconfdir = (& pg_config --sysconfdir 2>$null)
    if ($sysconfdir -and (Test-Path (Join-Path $sysconfdir 'pg_service.conf'))) {
        $PgServiceFile = Join-Path $sysconfdir 'pg_service.conf'
    }
}

# ---------------------------------------------------------------------------
# Extracts the host= value from inside the [SectionName] section of pg_service.conf
# ---------------------------------------------------------------------------

function Get-ServiceHost {
    param([string]$Path, [string]$Section)
    $inSection = $false
    foreach ($line in Get-Content -Path $Path) {
        if ($line -match '^\[(.+)\]$') {
            $inSection = ($Matches[1] -eq $Section)
            continue
        }
        if ($inSection -and $line -match '^\s*host\s*=\s*(.+?)\s*$') {
            return $Matches[1]
        }
    }
    return $null
}

# Extracts the region from an RDS hostname: the part before ".rds.amazonaws.com",
# or, in the AWS China partition, before ".amazonaws.com.cn" (only if it starts
# with "cn"). Returns $null if it can't be extracted.
function Get-RegionFromHost {
    param([string]$HostName)
    if ($HostName.EndsWith('.rds.amazonaws.com')) {
        $prefix = $HostName.Substring(0, $HostName.Length - '.rds.amazonaws.com'.Length)
        $parts = $prefix.Split('.')
        return $parts[$parts.Length - 1]
    } elseif ($HostName.EndsWith('.amazonaws.com.cn')) {
        $prefix = $HostName.Substring(0, $HostName.Length - '.amazonaws.com.cn'.Length)
        $parts = $prefix.Split('.')
        $candidate = $parts[$parts.Length - 1]
        if ($candidate.StartsWith('cn')) {
            return $candidate
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# If a pg_service.conf was found, builds the list of services in alphabetical
# order (always read fresh, never hard-coded), showing next to each one the
# db_instance_identifier extracted from its host. Services whose host is a
# VPC endpoint (not a direct RDS endpoint) are omitted from the list. Asks
# the user to pick one by number; if PGSERVICE is set and is a valid
# service, it becomes the default (Enter accepts it). If no pg_service
# exists, the db_instance_identifier is asked for manually further below.
# ---------------------------------------------------------------------------

$ServiceName = $env:SERVICE_NAME
$ServiceHostValue = $null

if (-not $ServiceName -and $PgServiceFile) {
    $rawServices = @()
    foreach ($line in Get-Content -Path $PgServiceFile) {
        if ($line -match '^\[(.+)\]$') {
            $rawServices += $Matches[1]
        }
    }

    $available = @()
    foreach ($svc in $rawServices) {
        $h = Get-ServiceHost -Path $PgServiceFile -Section $svc
        if (-not $h) { continue }
        if ($h.EndsWith('.vpce.amazonaws.com')) { continue }
        $id = $h.Split('.')[0]
        $available += [PSCustomObject]@{ Service = $svc; Id = $id; HostName = $h }
    }
    $available = @($available | Sort-Object Service)

    if ($available.Count -eq 0) {
        Write-Warning "No service with a valid RDS host found in $PgServiceFile."
        $PgServiceFile = $null
    } else {
        $defaultIndex = -1
        if ($env:PGSERVICE) {
            for ($i = 0; $i -lt $available.Count; $i++) {
                if ($available[$i].Service -eq $env:PGSERVICE) { $defaultIndex = $i; break }
            }
        }

        Write-Host "Available instances (from $PgServiceFile):"
        for ($i = 0; $i -lt $available.Count; $i++) {
            Write-Host ("{0,3}) {1} ({2})" -f ($i + 1), $available[$i].Service, $available[$i].Id)
        }

        $prompt = "Choose the instance [1-$($available.Count)]"
        if ($defaultIndex -ge 0) { $prompt += " (Enter uses PGSERVICE=$($available[$defaultIndex].Service))" }

        while ($true) {
            $choice = Read-Host -Prompt $prompt
            if ([string]::IsNullOrWhiteSpace($choice) -and $defaultIndex -ge 0) { $choice = [string]($defaultIndex + 1) }
            if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $available.Count) {
                $picked = $available[[int]$choice - 1]
                $ServiceName = $picked.Service
                $ServiceHostValue = $picked.HostName
                break
            } else {
                Write-Host "Invalid option, try again."
            }
        }
    }
}

if (-not $ServiceName -and -not $PgServiceFile) {
    Write-Host "No pg_service file found (PGSERVICEFILE, %APPDATA%\postgresql\.pg_service.conf, or <pg_config --sysconfdir>\pg_service.conf)."
}

# ---------------------------------------------------------------------------
# Real RDS instance/cluster identifier and region, extracted from the host:
#   - identifier = first part of the host, before the first dot
#   - region     = part of the host right before ".rds.amazonaws.com"
#     (or, in the AWS China partition, before ".amazonaws.com.cn", provided
#     the extracted value starts with "cn")
# ---------------------------------------------------------------------------

$DbInstanceIdentifier = $env:DB_INSTANCE_IDENTIFIER

if (-not $DbInstanceIdentifier -and $ServiceName) {
    if (-not $ServiceHostValue) {
        $ServiceHostValue = Get-ServiceHost -Path $PgServiceFile -Section $ServiceName
        if ($ServiceHostValue -and $ServiceHostValue.EndsWith('.vpce.amazonaws.com')) {
            Write-Warning "The host for '$ServiceName' looks like a VPC endpoint, not a direct RDS endpoint. The extracted db_instance_identifier may be wrong."
        }
    }

    if ($ServiceHostValue) {
        $DbInstanceIdentifier = $ServiceHostValue.Split('.')[0]

        if (-not $AwsRegion) {
            $AwsRegion = Get-RegionFromHost -HostName $ServiceHostValue
            if (-not $AwsRegion) {
                Write-Warning "Could not extract the region from host '$ServiceHostValue' (doesn't end in .rds.amazonaws.com or .amazonaws.com.cn with a 'cn*' region). Using the aws cli's default configured region."
            }
        }

        Write-Host "Host (pg_service):     $ServiceHostValue"
        Write-Host "  -> db_instance_identifier: $DbInstanceIdentifier"
        if ($AwsRegion) { Write-Host "  -> region:                 $AwsRegion" }
    } else {
        Write-Warning "Couldn't find a 'host' for service '$ServiceName' in $PgServiceFile."
    }
}

# ---------------------------------------------------------------------------
# No pg_service.conf: before asking for the db_instance_identifier manually,
# try using the PGHOST environment variable as a default value, extracting
# the identifier and region from it (same logic used for the pg_service host).
# ---------------------------------------------------------------------------

if (-not $DbInstanceIdentifier) {
    $defaultIdFromPgHost = $null

    if ($env:PGHOST) {
        $defaultIdFromPgHost = $env:PGHOST.Split('.')[0]

        if (-not $AwsRegion) {
            $AwsRegion = Get-RegionFromHost -HostName $env:PGHOST
            if (-not $AwsRegion) {
                Write-Warning "Could not extract the region from PGHOST='$($env:PGHOST)' (doesn't end in .rds.amazonaws.com or .amazonaws.com.cn with a 'cn*' region). Using the aws cli's default configured region."
            }
        }

        Write-Host "PGHOST detected:        $($env:PGHOST)"
        Write-Host "  -> db_instance_identifier: $defaultIdFromPgHost"
        if ($AwsRegion) { Write-Host "  -> region:                 $AwsRegion" }
    }

    if ($defaultIdFromPgHost) {
        $inputId = Read-Host -Prompt "Enter the db_instance_identifier (Enter uses '$defaultIdFromPgHost', extracted from PGHOST)"
        $DbInstanceIdentifier = if ([string]::IsNullOrWhiteSpace($inputId)) { $defaultIdFromPgHost } else { $inputId }
    } else {
        $DbInstanceIdentifier = Read-Host -Prompt "Enter the db_instance_identifier manually"
    }

    if ([string]::IsNullOrWhiteSpace($DbInstanceIdentifier)) {
        Write-Host "Error: db_instance_identifier cannot be empty."
        exit 1
    }
}

$DestDirName = if ($ServiceName) { $ServiceName } else { $DbInstanceIdentifier }
$DestDir = Join-Path $DestDirBase $DestDirName

$AwsCommonArgs = @('--db-instance-identifier', $DbInstanceIdentifier)
if ($AwsRegion) { $AwsCommonArgs += @('--region', $AwsRegion) }

if (-not (Test-Path $DestDir)) {
    Write-Host "Destination directory doesn't exist, creating: $DestDir"
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Minimum log date: asks how many days back to use (default: 2).
# Can be skipped by setting $env:DAYS_BEFORE or $env:MIN_DATE (yyyy-MM-dd).
# ---------------------------------------------------------------------------

$MinDate = $env:MIN_DATE
if (-not $MinDate) {
    $daysBefore = $env:DAYS_BEFORE
    if (-not $daysBefore) {
        $daysInput = Read-Host -Prompt "How many days back for the logs' minimum date? (Enter uses $DefaultDaysBefore)"
        if ([string]::IsNullOrWhiteSpace($daysInput)) {
            $daysBefore = $DefaultDaysBefore
        } elseif ($daysInput -match '^\d+$') {
            $daysBefore = [int]$daysInput
        } else {
            Write-Warning "Invalid value, using the default of $DefaultDaysBefore days."
            $daysBefore = $DefaultDaysBefore
        }
    }
    $MinDate = (Get-Date).ToUniversalTime().AddDays(-[int]$daysBefore).ToString('yyyy-MM-dd')
}

# Converts MinDate (yyyy-MM-dd) to epoch milliseconds (format required by the API filter)
$MinDateUtc = [DateTime]::SpecifyKind([DateTime]::ParseExact($MinDate, 'yyyy-MM-dd', $null), [DateTimeKind]::Utc)
$UnixEpoch = [DateTime]::SpecifyKind([DateTime]'1970-01-01', [DateTimeKind]::Utc)
$MinDateEpochMs = [long](($MinDateUtc - $UnixEpoch).TotalMilliseconds)

Write-Host ""
if ($ServiceName) { Write-Host "Service (pg_service):  $ServiceName" }
Write-Host "RDS instance:           $DbInstanceIdentifier"
Write-Host "Destination:            $DestDir"
Write-Host "Minimum date:           $MinDate"
Write-Host ""
Write-Host "Listing available logs..."

# ---------------------------------------------------------------------------
# Lists the log files matching the date filter (with pagination).
# ---------------------------------------------------------------------------

function Get-AllLogFiles {
    $files = @()
    $marker = $null
    while ($true) {
        $argList = @('rds', 'describe-db-log-files') + $AwsCommonArgs + @('--file-last-written', "$MinDateEpochMs")
        if ($marker) { $argList += @('--marker', $marker) }

        $page = Invoke-AwsJson -ArgumentList $argList
        if ($page -and $page.DescribeDBLogFiles) {
            foreach ($item in $page.DescribeDBLogFiles) {
                $files += [PSCustomObject]@{ Name = $item.LogFileName; Size = [long]$item.Size }
            }
        }

        $marker = $page.Marker
        if (-not $marker) { break }
    }
    return $files
}

# Formats bytes into a human-readable unit (B/KB/MB/GB/TB). Always uses "."
# as the decimal separator (invariant culture), regardless of the machine's
# regional settings (e.g. pt-BR formats numbers with "," by default).
function Format-Bytes {
    param([double]$Bytes)
    $units = @('B', 'KB', 'MB', 'GB', 'TB')
    $i = 0
    $b = $Bytes
    while ($b -ge 1024 -and $i -lt 4) {
        $b = $b / 1024
        $i++
    }
    $formatted = $b.ToString('F2', [System.Globalization.CultureInfo]::InvariantCulture)
    return "$formatted $($units[$i])"
}

# Available bytes on the drive holding the given directory
function Get-AvailableBytes {
    param([string]$Path)
    return [long](Get-Item -Path $Path).PSDrive.Free
}

$AllLogFiles = Get-AllLogFiles
$Total = $AllLogFiles.Count

if ($Total -eq 0) {
    Write-Host "No logs found from $MinDate onward."
    exit 0
}

Write-Host "Total logs to download: $Total"

$TotalLogBytes = 0
foreach ($f in $AllLogFiles) { $TotalLogBytes += $f.Size }

$AvailableBytes = Get-AvailableBytes -Path $DestDir

Write-Host "Total size of the logs:  $(Format-Bytes $TotalLogBytes)"
Write-Host "Available space in $DestDir : $(Format-Bytes $AvailableBytes)"

if ($TotalLogBytes -gt $AvailableBytes) {
    Write-Host ""
    Write-Host "Error: not enough disk space in $DestDir."
    Write-Host "  Needed:     $(Format-Bytes $TotalLogBytes)"
    Write-Host "  Available:  $(Format-Bytes $AvailableBytes)"
    Write-Host "Download aborted."
    exit 1
}

Write-Host ""

# ---------------------------------------------------------------------------
# Downloads a single log, paginating via Marker/AdditionalDataPending until done.
# Note: AdditionalDataPending comes back from ConvertFrom-Json as a real
# [bool] (JSON true/false), not a string - no case-insensitive string compare
# needed here, unlike the bash version working off aws cli's text output.
# ---------------------------------------------------------------------------

function Save-LogFile {
    param([string]$LogName, [string]$LocalPath)

    New-Item -ItemType File -Path $LocalPath -Force | Out-Null

    $marker = '0'
    while ($true) {
        $argList = @('rds', 'download-db-log-file-portion') + $AwsCommonArgs + @('--log-file-name', $LogName, '--marker', $marker)
        $portion = Invoke-AwsJson -ArgumentList $argList

        if ($null -ne $portion.LogFileData) {
            [System.IO.File]::AppendAllText($LocalPath, $portion.LogFileData + "`n")
        }

        $marker = $portion.Marker
        if (-not $portion.AdditionalDataPending) { break }
    }
}

# ---------------------------------------------------------------------------
# Downloads each log, showing progress
# ---------------------------------------------------------------------------

$Current = 0
$TotalBytes = 0
$LargestBytes = -1
$LargestName = ''
$SmallestBytes = -1
$SmallestName = ''

foreach ($log in $AllLogFiles) {
    $Current++
    $Remaining = $Total - $Current

    $localFileName = $log.Name -replace '/', '_'
    if ($localFileName.StartsWith('error_')) {
        $localFileName = $localFileName.Substring(6)
    }
    $localPath = Join-Path $DestDir $localFileName

    Write-Host "[$Current/$Total] Downloading: $($log.Name) ($Remaining remaining)"

    Save-LogFile -LogName $log.Name -LocalPath $localPath

    $fileSize = (Get-Item -Path $localPath).Length
    $TotalBytes += $fileSize

    if ($LargestBytes -lt 0 -or $fileSize -gt $LargestBytes) {
        $LargestBytes = $fileSize
        $LargestName = $localFileName
    }
    if ($SmallestBytes -lt 0 -or $fileSize -lt $SmallestBytes) {
        $SmallestBytes = $fileSize
        $SmallestName = $localFileName
    }
}

$AverageBytes = if ($Total -gt 0) { $TotalBytes / $Total } else { 0 }

Write-Host ""
Write-Host "Done. Files saved in:    $DestDir"
Write-Host "Files downloaded:        $Total"
Write-Host "Total size:              $(Format-Bytes $TotalBytes)"
Write-Host "Average size per file:   $(Format-Bytes $AverageBytes)"
Write-Host "Smallest file:           $(Format-Bytes $SmallestBytes) ($SmallestName)"
Write-Host "Largest file:            $(Format-Bytes $LargestBytes) ($LargestName)"

