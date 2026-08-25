<#
.SYNOPSIS
    Downloads PostgreSQL logs from an OCI Database with PostgreSQL DB system
    via the OCI CLI, filtered by a minimum date.

.DESCRIPTION
    Requirements: oci cli installed and configured (`oci setup config`), with
    access to the target compartment, the PostgreSQL DB system, and the
    Object Storage bucket the logs are exported to.

    IMPORTANT ARCHITECTURE DIFFERENCES / PREREQUISITES (same as the bash version):
      - OCI Database with PostgreSQL does NOT expose a "list/download log
        files" API by itself. Logs must first be explicitly configured to
        export to Object Storage:
          oci.log_destination = oci_object_storage
          oci.log_destination_os_namespace = <tenancy Object Storage namespace>
          oci.log_destination_os_bucket_name = <bucket name>
        This script does NOT set that up for you - it only reads what's
        already been exported.
      - Log objects follow this naming pattern (per Oracle's docs):
        <DB_SYSTEM_OCID>/<DB_INSTANCE_OCID>/postgresql-<DATE>_NNNNNN.csv.gz
        This script filters by the <DATE> embedded in the object name.
      - Logs are exported as gzip-compressed CSV. Set $env:DECOMPRESS = 'true'
        to gunzip them after download (done here with .NET's GZipStream, so
        no external gzip.exe is required on Windows).
      - Unlike the bash version (which needs a documented JMESPath join()
        trick because the OCI CLI has no --output text/tsv), this script just
        uses --output json everywhere and PowerShell's native ConvertFrom-Json.

    Windows note: by default, Windows blocks running unsigned .ps1 scripts.
    Run this with:
        powershell -ExecutionPolicy Bypass -File .\postgres_log_download_from_oci.ps1
    or, in an already-open session:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.NOTES
    Usage:
        .\postgres_log_download_from_oci.ps1
        (set the environment variables below to skip the prompts)
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------

# Base destination directory for downloaded logs (the DB system name is
# appended to this path, e.g.: C:\PostgreSQLLogs\my-db-system)
$DestDirBase = if ($env:DEST_DIR_BASE) { $env:DEST_DIR_BASE } else { 'C:\PostgreSQLLogs' }

# Default number of days back used for the logs' minimum date
$DefaultDaysBefore = 2

# Gunzip each .csv.gz after downloading (replaces the .gz with the plain file)
$Decompress = ($env:DECOMPRESS -eq 'true')

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

if (-not (Get-Command oci -ErrorAction SilentlyContinue)) {
    Write-Host "Error: oci cli not found in PATH."
    exit 1
}

# Runs an oci cli command and returns the parsed JSON output. Throws (which,
# uncaught, stops the whole script) if oci exits non-zero.
function Invoke-OciJson {
    param([string[]]$ArgumentList)
    $stdout = @(& oci @ArgumentList --output json)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "oci $($ArgumentList -join ' ') failed with exit code $exitCode."
    }
    $joined = ($stdout -join "`n")
    if ([string]::IsNullOrWhiteSpace($joined)) { return $null }
    return $joined | ConvertFrom-Json
}

# ---------------------------------------------------------------------------
# Compartment (OCI has no single global "project" like GCP; the compartment
# tree makes auto-discovery unreliable, so this is always asked/required).
# ---------------------------------------------------------------------------

$CompartmentId = $env:COMPARTMENT_ID
if (-not $CompartmentId) {
    $CompartmentId = Read-Host -Prompt "Enter the compartment OCID"
    if ([string]::IsNullOrWhiteSpace($CompartmentId)) {
        Write-Host "Error: compartment OCID cannot be empty."
        exit 1
    }
}

# ---------------------------------------------------------------------------
# DB system selection: dynamically listed from OCI (never hard-coded), in
# alphabetical order. Can be skipped by setting $env:DB_SYSTEM_ID (and
# optionally $env:DB_SYSTEM_NAME).
# ---------------------------------------------------------------------------

$DbSystemId = $env:DB_SYSTEM_ID
$DbSystemName = $env:DB_SYSTEM_NAME

if (-not $DbSystemId) {
    $response = Invoke-OciJson -ArgumentList @('psql', 'db-system-collection', 'list-db-systems',
        '--compartment-id', $CompartmentId, '--all')

    $available = @()
    if ($response -and $response.data -and $response.data.items) {
        foreach ($item in $response.data.items) {
            $available += [PSCustomObject]@{ Id = $item.id; Name = $item.'display-name' }
        }
    }
    $available = @($available | Sort-Object Name)

    if ($available.Count -eq 0) {
        Write-Host "Error: no PostgreSQL DB system found in compartment '$CompartmentId'."
        exit 1
    }

    Write-Host "Available PostgreSQL DB systems:"
    for ($i = 0; $i -lt $available.Count; $i++) {
        Write-Host ("{0,3}) {1} ({2})" -f ($i + 1), $available[$i].Name, $available[$i].Id)
    }

    while ($true) {
        $choice = Read-Host -Prompt "Choose the DB system [1-$($available.Count)]"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $available.Count) {
            $picked = $available[[int]$choice - 1]
            $DbSystemId = $picked.Id
            $DbSystemName = $picked.Name
            break
        } else {
            Write-Host "Invalid option, try again."
        }
    }
}

$DestDirName = if ($DbSystemName) { $DbSystemName } else { $DbSystemId }
$DestDir = Join-Path $DestDirBase $DestDirName
if (-not (Test-Path $DestDir)) {
    Write-Host "Destination directory doesn't exist, creating: $DestDir"
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Object Storage bucket holding the exported logs. There's no reliable way
# to auto-detect this from the DB system, so it's always asked/required.
# ---------------------------------------------------------------------------

$BucketName = $env:BUCKET_NAME
if (-not $BucketName) {
    $BucketName = Read-Host -Prompt "Enter the Object Storage bucket name where logs are exported"
    if ([string]::IsNullOrWhiteSpace($BucketName)) {
        Write-Host "Error: bucket name cannot be empty."
        exit 1
    }
}

$NamespaceName = $env:NAMESPACE_NAME
if (-not $NamespaceName) {
    $nsResponse = Invoke-OciJson -ArgumentList @('os', 'ns', 'get')
    if ($nsResponse) { $NamespaceName = $nsResponse.data }
    if (-not $NamespaceName) {
        Write-Host "Error: could not resolve the Object Storage namespace (oci os ns get). Set `$env:NAMESPACE_NAME manually."
        exit 1
    }
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

Write-Host ""
Write-Host "DB system:               $DestDirName"
Write-Host "Compartment:             $CompartmentId"
Write-Host "Bucket:                  $BucketName (namespace: $NamespaceName)"
Write-Host "Destination:             $DestDir"
Write-Host "Minimum date:            $MinDate"
Write-Host ""
Write-Host "Listing available logs..."

# ---------------------------------------------------------------------------
# Lists log objects under the DB system's prefix, then filters by the date
# embedded in the object name (postgresql-YYYY-MM-DD_NNNNNN.csv.gz).
# ---------------------------------------------------------------------------

$listResponse = Invoke-OciJson -ArgumentList @('os', 'object', 'list', '--bucket-name', $BucketName,
    '--namespace-name', $NamespaceName, '--prefix', "$DbSystemId/", '--all')

$AllLogFiles = @()
$UnparsedCount = 0

if ($listResponse -and $listResponse.data) {
    foreach ($item in $listResponse.data) {
        $name = $item.name
        $size = [long]$item.size

        if ($name -match 'postgresql-(\d{4}-\d{2}-\d{2})_') {
            $objDate = $Matches[1]
            if ($objDate -lt $MinDate) { continue }
        } else {
            $UnparsedCount++
        }

        $AllLogFiles += [PSCustomObject]@{ Name = $name; SizeBytes = $size }
    }
}

$Total = $AllLogFiles.Count

if ($Total -eq 0) {
    Write-Host "No logs found from $MinDate onward under prefix '$DbSystemId/' in bucket '$BucketName'."
    Write-Host "If this is unexpected, confirm log export to Object Storage is configured for this DB system (oci.log_destination = oci_object_storage)."
    exit 0
}

if ($UnparsedCount -gt 0) {
    Write-Warning "$UnparsedCount object name(s) didn't match the expected postgresql-YYYY-MM-DD_NNNNNN.csv.gz pattern; included anyway (date filter couldn't be applied to them)."
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

# Decompresses a .gz file in place (removing the .gz suffix), using .NET's
# GZipStream so no external gzip/gunzip binary is required on Windows.
function Expand-GzipFile {
    param([string]$Path)
    $destPath = $Path -replace '\.gz$', ''
    $inStream = [System.IO.File]::OpenRead($Path)
    try {
        $gzipStream = New-Object System.IO.Compression.GZipStream($inStream, [System.IO.Compression.CompressionMode]::Decompress)
        try {
            $outStream = [System.IO.File]::Create($destPath)
            try {
                $gzipStream.CopyTo($outStream)
            } finally {
                $outStream.Dispose()
            }
        } finally {
            $gzipStream.Dispose()
        }
    } finally {
        $inStream.Dispose()
    }
    Remove-Item -Path $Path -Force
    return $destPath
}

# ---------------------------------------------------------------------------
# Downloads each log, showing progress. Object names look like
# <DB_SYSTEM_OCID>/<DB_INSTANCE_OCID>/postgresql-<DATE>_NNNNNN.csv.gz; the
# local filename drops the DB system OCID and replaces the instance OCID
# with a short "nodeN" label assigned in order of first appearance, to keep
# names readable while avoiding collisions across instances.
#
# $InstanceLabels is a Hashtable (not parallel arrays) precisely because a
# function needs to add entries to it as it runs: PowerShell functions get
# their own scope, so `$InstanceLabels += $x` *inside* a function would
# silently create a local shadow copy instead of updating this one - the
# exact bug the bash version had with a subshell via `$(...)`. Mutating an
# existing Hashtable's contents (`$InstanceLabels[$key] = $value`) works
# correctly across scopes because it's not a reassignment of the variable.
# ---------------------------------------------------------------------------

$InstanceLabels = @{}

function Get-InstanceLabel {
    param([string]$InstanceId)
    if ($InstanceLabels.ContainsKey($InstanceId)) {
        return $InstanceLabels[$InstanceId]
    }
    $label = "node$($InstanceLabels.Count + 1)"
    $InstanceLabels[$InstanceId] = $label
    return $label
}

$Current = 0
$TotalBytes = 0
$LargestBytes = -1
$LargestName = ''
$SmallestBytes = -1
$SmallestName = ''

foreach ($obj in $AllLogFiles) {
    $Current++
    $Remaining = $Total - $Current

    $segments = $obj.Name.Split('/')
    $instanceId = if ($segments.Length -ge 2) { $segments[1] } else { 'unknown' }
    $baseName = $segments[$segments.Length - 1]
    $label = Get-InstanceLabel -InstanceId $instanceId
    $localFileName = "${label}_${baseName}"
    $localPath = Join-Path $DestDir $localFileName

    Write-Host "[$Current/$Total] Downloading: $($obj.Name) ($Remaining remaining)"

    & oci os object get --bucket-name $BucketName --namespace-name $NamespaceName `
        --name $obj.Name --file $localPath *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "oci os object get failed with exit code $LASTEXITCODE for '$($obj.Name)'."
    }

    if ($Decompress -and $localPath -like '*.gz') {
        $localPath = Expand-GzipFile -Path $localPath
        $localFileName = $localFileName -replace '\.gz$', ''
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

