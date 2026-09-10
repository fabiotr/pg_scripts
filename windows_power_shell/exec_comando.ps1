<#
.SYNOPSIS
    Executes a SQL command (comando.sql) across all databases in the cluster.
    Windows PowerShell port of exec_comando.sh (same behavior, same file name).

.DESCRIPTION
    Requirements: psql.exe on PATH.
    Edit comando.sql first to choose which script or command to run, then
    execute this script to run it against every database in the cluster,
    except 'postgres' and template databases.

.NOTES
    Usage:
        .\exec_comando.ps1
    Windows note: by default, Windows blocks running unsigned .ps1 scripts.
    Run this with:
        powershell -ExecutionPolicy Bypass -File .\exec_comando.ps1
#>

$ErrorActionPreference = 'Stop'

# Find psql binary location
$Psql = (Get-Command psql -ErrorAction SilentlyContinue).Source
if (-not $Psql) {
    Write-Error "psql not found on PATH."
    exit 1
}

# Get the list of existing databases (excluding 'postgres' and templates)
$DbNames = & $Psql -t -c "SELECT datname FROM pg_database WHERE datname != 'postgres' AND datistemplate = FALSE" |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' }

# Run comando.sql against each database
foreach ($db in $DbNames) {
    & $Psql -t -f comando.sql $db
}
