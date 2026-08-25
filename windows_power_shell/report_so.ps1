#Requires -Version 5.1
<#
Windows OS report for PostgreSQL 

Run elevated (Run as Administrator) for complete output — the "Lock Pages in Memory"
check and some registry reads are silently incomplete otherwise.
#>

$fileDest = "$env:TEMP\so.md"
$hostName = $env:COMPUTERNAME

Remove-Item -Path $fileDest -ErrorAction SilentlyContinue
New-Item -Path $fileDest -ItemType File -Force | Out-Null

function Write-Report {
    param([string]$Text = "")
    Add-Content -Path $fileDest -Value $Text -Encoding UTF8
}

function Write-ReportBlock {
    param([object]$Object)
    ($Object | Out-String).TrimEnd() -split "`r?`n" | ForEach-Object { Write-Report $_ }
}

Write-Report "# 🐘 OS Report for $hostName"
Write-Report "- Date:     $(Get-Date)"
Write-Report "- Host:     $hostName"
Write-Report ""
Write-Report "## 📌 Index"
Write-Report ""
Write-Report "[[_TOC_]]"
Write-Report ""

# ------------------------------------------------------------------
Write-Report "## 📊 CPU"
Write-Report '```text'
Get-CimInstance Win32_Processor |
    Select-Object Name, Manufacturer, Architecture, NumberOfCores, NumberOfLogicalProcessors, `
        MaxClockSpeed, L2CacheSize, L3CacheSize |
    Write-ReportBlock
Write-Report '```'
Write-Report ""

# ------------------------------------------------------------------
Write-Report "## 📊 Network"
Write-Report '```text'
Write-Report ("{0,-16} {1,-10} {2,-20} {3,-30}" -f "Interface", "State", "IPv4/Mask", "IPv6/Mask")
Write-Report ("-" * 80)
Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceType -ne 24 } | ForEach-Object {
    $ifName = $_.Name
    $state  = $_.Status
    $ipv4   = Get-NetIPAddress -InterfaceAlias $ifName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
    $ipv4Str = if ($ipv4) { "$($ipv4.IPAddress)/$($ipv4.PrefixLength)" } else { "N/A" }
    $ipv6   = Get-NetIPAddress -InterfaceAlias $ifName -AddressFamily IPv6 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notmatch '^fe80' } | Select-Object -First 1
    $ipv6Str = if ($ipv6) { "$($ipv6.IPAddress)/$($ipv6.PrefixLength)" } else { "N/A" }
    Write-Report ("{0,-16} {1,-10} {2,-20} {3,-30}" -f $ifName, $state, $ipv4Str, $ipv6Str)
}
Write-Report '```'
Write-Report ""

# ------------------------------------------------------------------
Write-Report "## 📊 Memory"
Write-Report '```text'
$os = Get-CimInstance Win32_OperatingSystem
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedGB  = [math]::Round($totalGB - $freeGB, 2)
Write-Report ("Total: {0} GB   Used: {1} GB   Free: {2} GB" -f $totalGB, $usedGB, $freeGB)
Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Report ("Pagefile {0}: Allocated {1} MB, InUse {2} MB" -f $_.Name, $_.AllocatedBaseSize, $_.CurrentUsage)
}
Write-Report '```'
Write-Report ""

# ------------------------------------------------------------------
Write-Report "## 🛠️ Large Pages"

Write-Report "### Lock Pages in Memory privilege"
Write-Report '```text'
$secTmp = "$env:TEMP\secpol_$PID.inf"
secedit /export /cfg $secTmp /areas USER_RIGHTS *> $null
$privLine = Select-String -Path $secTmp -Pattern "SeLockMemoryPrivilege" -ErrorAction SilentlyContinue
if ($privLine) { Write-Report $privLine.Line } else { Write-Report "SeLockMemoryPrivilege is not assigned to any account (or insufficient rights to check — run elevated)" }
Remove-Item -Path $secTmp -ErrorAction SilentlyContinue
Write-Report '```'
Write-Report ""

Write-Report "### PostgreSQL process memory (equivalent to VmPeak)"
Write-Report '```text'
$pgProc = Get-Process postgres -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pgProc) {
    Write-Report ("PeakWorkingSet:         {0} MB" -f [math]::Round($pgProc.PeakWorkingSet64 / 1MB, 2))
    Write-Report ("PeakVirtualMemorySize:  {0} MB" -f [math]::Round($pgProc.PeakVirtualMemorySize64 / 1MB, 2))
} else {
    Write-Report "No PostgreSQL active now"
}
Write-Report '```'
Write-Report ""

# ------------------------------------------------------------------
Write-Report "## 📂 Discs"
Write-Report "### Volumes"
Write-Report '```text'
Write-Report ("{0,-6} {1,-8} {2,10} {3,10}  {4}" -f "Drive", "FS", "SizeGB", "FreeGB", "Label")
Write-Report ("-" * 60)
Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter } | Sort-Object DriveLetter | ForEach-Object {
    $sizeGB = [math]::Round($_.Size / 1GB, 2)
    $freeGB = [math]::Round($_.SizeRemaining / 1GB, 2)
    Write-Report ("{0,-6} {1,-8} {2,10} {3,10}  {4}" -f "$($_.DriveLetter):", $_.FileSystem, $sizeGB, $freeGB, $_.FileSystemLabel)
}
Write-Report '```'
Write-Report ""

# ------------------------------------------------------------------
Write-Report "## 🛠️ Windows"

Write-Report "### OS / Hardware"
Write-Report '```text'
$osInfo = Get-CimInstance Win32_OperatingSystem
$csInfo = Get-CimInstance Win32_ComputerSystem
Write-Report ("Operating System: {0} (Build {1})" -f $osInfo.Caption, $osInfo.BuildNumber)
Write-Report ("Virtualization:    {0}" -f $csInfo.Model)
Write-Report ("Hardware Vendor:   {0}" -f $csInfo.Manufacturer)
Write-Report ("Hardware Model:    {0}" -f $csInfo.Model)
Write-Report '```'
Write-Report ""

Write-Report "### TCP/IP parameters (registry — equivalent to sysctl net.*)"
Write-Report '```text'
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -ErrorAction SilentlyContinue |
    Select-Object TcpTimedWaitDelay, MaxUserPort, TcpNumConnections |
    Write-ReportBlock
Write-Report '```'
Write-Report ""

Write-Report "### Memory management parameters (registry — equivalent to sysctl vm.*)"
Write-Report '```text'
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -ErrorAction SilentlyContinue |
    Select-Object LargePageMinimum, DisablePagingExecutive, LargeSystemCache |
    Write-ReportBlock
Write-Report '```'
Write-Report ""

Write-Report "### Storage (equivalent to I/O scheduler)"
Write-Report '```text'
Write-Report ("{0,-8} {1,-10} {2,-10}" -f "Disk", "Media", "Bus")
Write-Report ("-" * 32)
Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Report ("{0,-8} {1,-10} {2,-10}" -f $_.DeviceId, $_.MediaType, $_.BusType)
}
Write-Report '```'
Write-Report ""

Write-Report "### Scheduled Tasks ($env:USERNAME)"
Write-Report '```text'
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.Principal.UserId -like "*$env:USERNAME*" -and $_.State -ne 'Disabled' } |
    Select-Object TaskName, TaskPath, State |
    Write-ReportBlock
Write-Report '```'
Write-Report ""

Write-Report "### Scheduled Tasks (non-Microsoft)"
Write-Report '```text'
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskPath -notlike "\Microsoft*" -and $_.State -ne 'Disabled' } |
    Select-Object TaskName, TaskPath, State |
    Write-ReportBlock
Write-Report '```'
Write-Report ""

Write-Report "### PostgreSQL related packages"
Write-Report '```text'
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
Get-ItemProperty -Path $uninstallPaths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'postgres|pgbackrest|pgbadger|pg_|pgAdmin' } |
    Select-Object DisplayName, DisplayVersion -Unique |
    Sort-Object DisplayName |
    Write-ReportBlock
Write-Report '```'
Write-Report ""

Write-Report "### Locale"
Write-Report '```text'
Write-Report ("System Locale: {0}" -f (Get-WinSystemLocale -ErrorAction SilentlyContinue).Name)
Write-Report '```'
Write-Report ""

Write-Report "### Timezone"
Write-Report '```text'
$tz = Get-TimeZone -ErrorAction SilentlyContinue
Write-Report ("Time zone: {0}" -f $tz.Id)
$syncLine = w32tm /query /status 2>$null | Select-String "Source"
if ($syncLine) { Write-Report ("Sync source: {0}" -f $syncLine.Line.Trim()) }
Write-Report '```'
Write-Report ""

Write-Report "### Environment Variables"
Write-Report '```powershell'
Write-Report "USERNAME=$env:USERNAME"
Write-Report "USERPROFILE=$env:USERPROFILE"
Write-Report "PATH=$env:PATH"
Get-ChildItem Env: | Where-Object { $_.Name -like 'PG*' -and $_.Name -ne 'PGPASSWORD' } | ForEach-Object {
    Write-Report "$($_.Name)=$($_.Value)"
}
if ($env:PGPASSWORD) { Write-Report "PGPASSWORD=*****" }
Write-Report '```'
Write-Report ""

Write-Report "### pgpass.conf"
Write-Report '```text'
$pgpassFile = if ($env:PGPASSFILE) { $env:PGPASSFILE } else { Join-Path $env:APPDATA "postgresql\pgpass.conf" }
if (Test-Path $pgpassFile) {
    Write-Report "File: $pgpassFile"
    Get-Content $pgpassFile | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } | ForEach-Object {
        $parts = $_ -split ':'
        if ($parts.Count -ge 4) { Write-Report ("{0}:{1}:{2}:{3}:*****" -f $parts[0], $parts[1], $parts[2], $parts[3]) }
    }
} else {
    Write-Report "No pgpass.conf found"
}
Write-Report '```'
Write-Report ""

Write-Report "### pg_service.conf"
Write-Report '```text'
$pgServiceFile = if ($env:PGSERVICEFILE) { $env:PGSERVICEFILE } else { Join-Path $env:APPDATA "postgresql\pg_service.conf" }
if (Test-Path $pgServiceFile) {
    Write-Report "File: $pgServiceFile"
    Get-Content $pgServiceFile | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } | ForEach-Object { Write-Report $_ }
} else {
    Write-Report "No pg_service.conf found"
}
Write-Report '```'
Write-Report ""

Write-Report "### psqlrc.conf"
Write-Report '```sql'
$psqlrcFile = Join-Path $env:APPDATA "postgresql\psqlrc.conf"
if (Test-Path $psqlrcFile) {
    Get-Content $psqlrcFile | Where-Object { $_ -notmatch '^--' } | ForEach-Object { Write-Report $_ }
}
Write-Report '```'
Write-Report ""

Write-Report "END"

Get-Content $fileDest

