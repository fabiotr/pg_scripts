<#
.SYNOPSIS
    Downloads PostgreSQL server logs from an Azure Database for PostgreSQL
    Flexible Server instance via the Azure CLI (az), filtered by a minimum date.

.DESCRIPTION
    Requirements: az cli installed and logged in (`az login`), with access to
    the target subscription/resource group.

    IMPORTANT NOTES (same as the bash version):
      - Log capture for download is DISABLED by default on Azure Database for
        PostgreSQL Flexible Server. This script only reads/downloads; it does
        NOT enable capture for you. Enable it first with:
          az postgres flexible-server parameter set -g <group> -s <server> `
            --name logfiles.download_enable --value on
        Retention is 1-7 days (server parameter logfiles.retention_days).
        This script warns (but doesn't stop) if the parameter looks disabled.
      - `server-logs list` filters by --file-last-written in HOURS (not
        days), default 72h if unset - this script converts the usual "days
        back" prompt to hours for you.
      - `server-logs download` writes files to the CURRENT DIRECTORY using
        the log's name as-is, which per Microsoft's own example can include a
        folder-style prefix (e.g. "serverlogs/f1.log"). This script downloads
        into $DestDir (via Push-Location) and then flattens that prefix, same
        idea as the RDS version stripping its "error_" prefix.
      - Unlike the bash version (which uses --output tsv + JMESPath tricks to
        avoid needing jq), this script just uses --output json everywhere and
        PowerShell's native ConvertFrom-Json + Sort-Object - simpler, and
        nothing extra to install.

    Windows note: by default, Windows blocks running unsigned .ps1 scripts.
    Run this with:
        powershell -ExecutionPolicy Bypass -File .\postgres_log_download_from_azure.ps1
    or, in an already-open session:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.NOTES
    Usage:
        .\postgres_log_download_from_azure.ps1
        (set the environment variables below to skip the prompts)
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------

# Base destination directory for downloaded logs (the server name is
# appended to this path, e.g.: C:\PostgreSQLLogs\my-server)
$DestDirBase = if ($env:DEST_DIR_BASE) { $env:DEST_DIR_BASE } else { 'C:\PostgreSQLLogs' }

# Default number of days back used for the logs' minimum date
$DefaultDaysBefore = 2

# Azure subscription (optional; if empty, uses az's current active subscription)
$AzSubscription = $env:AZ_SUBSCRIPTION

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Error: az cli not found in PATH."
    exit 1
}

$AzArgs = @()
if ($AzSubscription) { $AzArgs += @('--subscription', $AzSubscription) }

& az account show @AzArgs *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: not logged in to az cli (or subscription not found). Run 'az login' first."
    exit 1
}

# Runs an az cli command and returns the parsed JSON output. Throws (which,
# uncaught, stops the whole script) if az exits non-zero.
function Invoke-AzJson {
    param([string[]]$ArgumentList)
    $stdout = @(& az @ArgumentList --output json)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "az $($ArgumentList -join ' ') failed with exit code $exitCode."
    }
    $joined = ($stdout -join "`n")
    if ([string]::IsNullOrWhiteSpace($joined)) { return $null }
    return $joined | ConvertFrom-Json
}

# Runs an az cli command and returns a single trimmed text value (tsv output).
function Invoke-AzTsv {
    param([string[]]$ArgumentList)
    $stdout = @(& az @ArgumentList --output tsv)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) { return $null }
    return ($stdout -join "`n").Trim()
}

# ---------------------------------------------------------------------------
# Server selection: dynamically listed from Azure (never hard-coded), in
# alphabetical order, showing the resource group and region next to each
# name. Can be skipped by setting $env:SERVER_NAME and $env:RESOURCE_GROUP.
# ---------------------------------------------------------------------------

$ServerName = $env:SERVER_NAME
$ResourceGroup = $env:RESOURCE_GROUP
$ServerRegion = $null

if (-not $ServerName -or -not $ResourceGroup) {
    $servers = Invoke-AzJson -ArgumentList (@('postgres', 'flexible-server', 'list') + $AzArgs +
        @('--query', '[].{name:name, rg:resourceGroup, region:region}'))

    $available = @()
    if ($servers) { $available = @($servers | Sort-Object name) }

    if ($available.Count -eq 0) {
        Write-Host "Error: no Azure Database for PostgreSQL Flexible Server found in this subscription."
        exit 1
    }

    Write-Host "Available PostgreSQL Flexible Server instances:"
    for ($i = 0; $i -lt $available.Count; $i++) {
        Write-Host ("{0,3}) {1} ({2}, {3})" -f ($i + 1), $available[$i].name, $available[$i].rg, $available[$i].region)
    }

    while ($true) {
        $choice = Read-Host -Prompt "Choose the instance [1-$($available.Count)]"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $available.Count) {
            $picked = $available[[int]$choice - 1]
            $ServerName = $picked.name
            $ResourceGroup = $picked.rg
            $ServerRegion = $picked.region
            break
        } else {
            Write-Host "Invalid option, try again."
        }
    }
}

$DestDir = Join-Path $DestDirBase $ServerName
if (-not (Test-Path $DestDir)) {
    Write-Host "Destination directory doesn't exist, creating: $DestDir"
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Warns (without stopping) if log capture for download looks disabled.
# ---------------------------------------------------------------------------

$downloadEnable = Invoke-AzTsv -ArgumentList (@('postgres', 'flexible-server', 'parameter', 'show') + $AzArgs +
    @('--resource-group', $ResourceGroup, '--server-name', $ServerName, '--name', 'logfiles.download_enable', '--query', 'value'))

if ($downloadEnable -and $downloadEnable.ToLowerInvariant() -ne 'on') {
    Write-Warning "Log capture for download (logfiles.download_enable) looks OFF for '$ServerName'. No logs may be available until it's turned on (az postgres flexible-server parameter set --name logfiles.download_enable --value on)."
}

# ---------------------------------------------------------------------------
# Minimum log date: asks how many days back to use (default: 2), converted
# to hours for --file-last-written. Can be skipped by setting $env:DAYS_BEFORE.
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

$HoursBack = [int]$daysBefore * 24

Write-Host ""
Write-Host "Server:                  $ServerName"
Write-Host "Resource group:          $ResourceGroup"
if ($ServerRegion) { Write-Host "Region:                  $ServerRegion" }
Write-Host "Destination:             $DestDir"
Write-Host "Minimum date:            last $daysBefore day(s) ($HoursBack hours)"
Write-Host ""
Write-Host "Listing available logs..."

# ---------------------------------------------------------------------------
# Lists the log files matching the date filter.
# ---------------------------------------------------------------------------

$logsResponse = Invoke-AzJson -ArgumentList (@('postgres', 'flexible-server', 'server-logs', 'list') + $AzArgs +
    @('--resource-group', $ResourceGroup, '--server-name', $ServerName, '--file-last-written', "$HoursBack",
      '--query', '[].{name:name, sizeInKB:sizeInKB}'))

$AllLogFiles = @()
if ($logsResponse) {
    foreach ($item in $logsResponse) {
        $AllLogFiles += [PSCustomObject]@{ Name = $item.name; SizeBytes = [long]$item.sizeInKB * 1024 }
    }
}

$Total = $AllLogFiles.Count

if ($Total -eq 0) {
    Write-Host "No logs found in the last $daysBefore day(s)."
    exit 0
}

Write-Host "Total logs to download: $Total"

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

$TotalLogBytes = 0
foreach ($f in $AllLogFiles) { $TotalLogBytes += $f.SizeBytes }

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
# Downloads each log, showing progress. `server-logs download` writes to the
# current directory using the log's name as-is (which may include a
# folder-style prefix), so we Push-Location into $DestDir and then flatten
# the result to a plain filename.
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

    Write-Host "[$Current/$Total] Downloading: $($log.Name) ($Remaining remaining)"

    Push-Location $DestDir
    try {
        & az postgres flexible-server server-logs download @AzArgs `
            --resource-group $ResourceGroup --server-name $ServerName --name $log.Name *> $null
        $downloadExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    if ($downloadExit -ne 0) {
        throw "az postgres flexible-server server-logs download failed with exit code $downloadExit for '$($log.Name)'."
    }

    $downloadedPath = Join-Path $DestDir $log.Name
    $localFileName = $log.Name -replace '.*/', ''
    $localPath = Join-Path $DestDir $localFileName

    if ($downloadedPath -ne $localPath -and (Test-Path $downloadedPath)) {
        Move-Item -Path $downloadedPath -Destination $localPath -Force
        $downloadedDir = Split-Path -Path $downloadedPath -Parent
        if ($downloadedDir -ne $DestDir -and (Test-Path $downloadedDir)) {
            if (-not (Get-ChildItem -Path $downloadedDir -Force -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $downloadedDir -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if (-not (Test-Path $localPath)) {
        Write-Warning "'$($log.Name)' wasn't found after download (it may no longer be available on the server)."
        continue
    }

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

