<#
.SYNOPSIS
    Downloads PostgreSQL logs from a Cloud SQL instance via the gcloud CLI
    (Cloud Logging), filtered by a minimum date.

.DESCRIPTION
    Requirements: gcloud cli installed and authenticated, with access to
    Cloud SQL Admin and Cloud Logging for the target project.

    IMPORTANT ARCHITECTURE DIFFERENCES FROM THE RDS VERSION:
      - Cloud SQL/Cloud Logging has no per-file log listing like RDS's
        describe-db-log-files. Logs are a queryable stream of entries, so
        this script downloads one text file PER DAY instead of per log file.
      - There is no API that reports exact log size ahead of time. The size
        shown before downloading is an ESTIMATE (entry count x sampled
        average entry size), clearly labeled as such.
      - gcloud's --format=value(...) already extracts plain text client-side,
        so this script parses text output directly - no JSON/ConvertFrom-Json
        needed at all here (there's nothing for it to replace, unlike the
        RDS port where it replaces jq).
      - Cloud SQL logs are usually in the `textPayload` field. If you've
        enabled structured PostgreSQL logging, set $env:LOG_PAYLOAD_FIELD =
        'jsonPayload.message' instead.

    Windows note: by default, Windows blocks running unsigned .ps1 scripts.
    Run this with:
        powershell -ExecutionPolicy Bypass -File .\postgres_log_download_from_gcp_sql.ps1
    or, in an already-open session:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.NOTES
    Usage:
        .\postgres_log_download_from_gcp_sql.ps1
        (set the environment variables below to skip the prompts)
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------

# Base destination directory for downloaded logs (the instance name is
# appended to this path, e.g.: C:\PostgreSQLLogs\my-instance)
$DestDirBase = if ($env:DEST_DIR_BASE) { $env:DEST_DIR_BASE } else { 'C:\PostgreSQLLogs' }

# Default number of days back used for the logs' minimum date
$DefaultDaysBefore = 2

# Number of entries sampled per day to estimate the average entry size
$SampleSize = if ($env:SAMPLE_SIZE) { [int]$env:SAMPLE_SIZE } else { 20 }

# Field holding the log text. Cloud SQL PostgreSQL logs are usually plain
# text in `textPayload`; if structured logging is enabled, use
# `jsonPayload.message` instead.
$LogPayloadField = if ($env:LOG_PAYLOAD_FIELD) { $env:LOG_PAYLOAD_FIELD } else { 'textPayload' }

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "Error: gcloud cli not found in PATH."
    exit 1
}

# Runs a gcloud command and returns its stdout as an array of lines. Throws
# (which, uncaught, stops the whole script) if gcloud exits non-zero.
function Invoke-Gcloud {
    param([string[]]$ArgumentList)
    $stdout = @(& gcloud @ArgumentList)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "gcloud $($ArgumentList -join ' ') failed with exit code $exitCode."
    }
    return $stdout
}

# ---------------------------------------------------------------------------
# GCP project
# ---------------------------------------------------------------------------

$GcpProject = $env:GCP_PROJECT

if (-not $GcpProject) {
    $configured = (& gcloud config get-value project 2>$null)
    if ($configured -and $configured -ne '(unset)') { $GcpProject = $configured }
}

if (-not $GcpProject) {
    $GcpProject = Read-Host -Prompt "Enter the GCP project id"
    if ([string]::IsNullOrWhiteSpace($GcpProject)) {
        Write-Host "Error: project id cannot be empty."
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Instance selection: dynamically listed from Cloud SQL (PostgreSQL only,
# never hard-coded), in alphabetical order, showing the region next to each
# name. Can be skipped by setting $env:INSTANCE_NAME (and optionally
# $env:INSTANCE_REGION) before running.
# ---------------------------------------------------------------------------

$InstanceName = $env:INSTANCE_NAME
$InstanceRegion = $env:INSTANCE_REGION

if (-not $InstanceName) {
    $available = @()
    $lines = Invoke-Gcloud -ArgumentList @('sql', 'instances', 'list', "--project=$GcpProject",
        '--filter=databaseVersion:POSTGRES*', '--format=value(name,region)')
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split "`t"
        $available += [PSCustomObject]@{ Name = $parts[0]; Region = $parts[1] }
    }
    $available = @($available | Sort-Object Name)

    if ($available.Count -eq 0) {
        Write-Host "Error: no Cloud SQL PostgreSQL instance found in project '$GcpProject'."
        exit 1
    }

    Write-Host "Available PostgreSQL instances in project '$GcpProject':"
    for ($i = 0; $i -lt $available.Count; $i++) {
        Write-Host ("{0,3}) {1} ({2})" -f ($i + 1), $available[$i].Name, $available[$i].Region)
    }

    while ($true) {
        $choice = Read-Host -Prompt "Choose the instance [1-$($available.Count)]"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $available.Count) {
            $picked = $available[[int]$choice - 1]
            $InstanceName = $picked.Name
            $InstanceRegion = $picked.Region
            break
        } else {
            Write-Host "Invalid option, try again."
        }
    }
}

if (-not $InstanceRegion) {
    $InstanceRegion = (Invoke-Gcloud -ArgumentList @('sql', 'instances', 'describe', $InstanceName, "--project=$GcpProject", '--format=value(region)')) -join ''
}

$DestDir = Join-Path $DestDirBase $InstanceName
if (-not (Test-Path $DestDir)) {
    Write-Host "Destination directory doesn't exist, creating: $DestDir"
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Minimum log date: asks how many days back to use (default: 2).
# Can be skipped by setting $env:DAYS_BEFORE.
# ---------------------------------------------------------------------------

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

$MinDateUtc = (Get-Date).ToUniversalTime().Date.AddDays(-[int]$daysBefore)
$TodayUtc = (Get-Date).ToUniversalTime().Date

Write-Host ""
Write-Host "Project:                $GcpProject"
Write-Host "Instance:                $InstanceName"
Write-Host "Region:                  $InstanceRegion"
Write-Host "Destination:             $DestDir"
Write-Host "Minimum date:            $($MinDateUtc.ToString('yyyy-MM-dd'))"
Write-Host ""

# ---------------------------------------------------------------------------
# Builds the list of days to download (one log file per day).
# ---------------------------------------------------------------------------

$AllDays = @()
$d = $MinDateUtc
while ($d -le $TodayUtc) {
    $AllDays += $d
    $d = $d.AddDays(1)
}

$Total = $AllDays.Count

if ($Total -eq 0) {
    Write-Host "No days to process from $($MinDateUtc.ToString('yyyy-MM-dd')) onward."
    exit 0
}

Write-Host "Total days to download: $Total"

# Builds the Cloud Logging filter for a single day (UTC boundaries).
function Get-DayFilter {
    param([DateTime]$Day)
    $dayStart = $Day.ToString('yyyy-MM-ddT00:00:00Z')
    $dayEnd = $Day.AddDays(1).ToString('yyyy-MM-ddT00:00:00Z')
    return 'resource.type="cloudsql_database" AND resource.labels.database_id="' + $GcpProject + ':' + $InstanceName + '" AND logName="projects/' + $GcpProject + '/logs/cloudsql.googleapis.com%2Fpostgres.log" AND timestamp>="' + $dayStart + '" AND timestamp<"' + $dayEnd + '"'
}

# Formats bytes into a human-readable unit (B/KB/MB/GB/TB). Always uses "."
# as the decimal separator (invariant culture) regardless of regional settings.
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

# ---------------------------------------------------------------------------
# Estimates the total size to download: counts entries per day and samples a
# few to get an average entry size, since Cloud Logging has no API that
# reports exact byte size ahead of time (unlike RDS's Size field).
# ---------------------------------------------------------------------------

Write-Host "Estimating total log size (this queries Cloud Logging, may take a moment)..."

$TotalEstimatedBytes = 0
$DayEntryCounts = @()

foreach ($day in $AllDays) {
    $filter = Get-DayFilter -Day $day

    $entryLines = @(Invoke-Gcloud -ArgumentList @('logging', 'read', $filter, "--project=$GcpProject", '--format=value(timestamp)'))
    $entryLines = @($entryLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $entryCount = $entryLines.Count
    $DayEntryCounts += $entryCount

    if ($entryCount -gt 0) {
        $sampleLines = @(Invoke-Gcloud -ArgumentList @('logging', 'read', $filter, "--project=$GcpProject",
            "--limit=$SampleSize", "--format=value($LogPayloadField)"))
        $sampleCount = [Math]::Min($entryCount, $SampleSize)
        if ($sampleCount -gt 0 -and $sampleLines.Count -gt 0) {
            $sampleBytes = [System.Text.Encoding]::UTF8.GetByteCount(($sampleLines -join "`n"))
            $avgEntryBytes = $sampleBytes / $sampleCount
            $TotalEstimatedBytes += [long]($avgEntryBytes * $entryCount)
        }
    }
}

$AvailableBytes = Get-AvailableBytes -Path $DestDir

Write-Host "Estimated total size:    $(Format-Bytes $TotalEstimatedBytes) (estimate, not exact)"
Write-Host "Available space in $DestDir : $(Format-Bytes $AvailableBytes)"

if ($TotalEstimatedBytes -gt $AvailableBytes) {
    Write-Host ""
    Write-Host "Error: not enough disk space in $DestDir."
    Write-Host "  Estimated needed: $(Format-Bytes $TotalEstimatedBytes)"
    Write-Host "  Available:        $(Format-Bytes $AvailableBytes)"
    Write-Host "Download aborted."
    exit 1
}

Write-Host ""

# ---------------------------------------------------------------------------
# Downloads each day's logs, showing progress
# ---------------------------------------------------------------------------

$Current = 0
$TotalBytes = 0
$LargestBytes = -1
$LargestName = ''
$SmallestBytes = -1
$SmallestName = ''

for ($idx = 0; $idx -lt $AllDays.Count; $idx++) {
    $day = $AllDays[$idx]
    $dayStr = $day.ToString('yyyy-MM-dd')
    $Current++
    $Remaining = $Total - $Current

    $localFileName = "postgresql.log.$dayStr"
    $localPath = Join-Path $DestDir $localFileName

    Write-Host "[$Current/$Total] Downloading: $dayStr ($($DayEntryCounts[$idx]) entries, $Remaining remaining)"

    $filter = Get-DayFilter -Day $day
    $lines = Invoke-Gcloud -ArgumentList @('logging', 'read', $filter, "--project=$GcpProject", '--order=asc', "--format=value($LogPayloadField)")
    [System.IO.File]::WriteAllText($localPath, ($lines -join "`n"), [System.Text.Encoding]::UTF8)

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

