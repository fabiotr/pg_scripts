#!/usr/bin/env bash
#
# Downloads PostgreSQL server logs from an Azure Database for PostgreSQL
# Flexible Server instance via the Azure CLI (az), filtered by a minimum
# date.
#
# Requirements: az cli installed and logged in (`az login`), with access to
# the target subscription/resource group.
#
# IMPORTANT NOTES:
#   - Log capture for download is DISABLED by default on Azure Database for
#     PostgreSQL Flexible Server. This script only reads/downloads; it does
#     NOT enable capture for you (that changes a server parameter). Enable it
#     first with:
#       az postgres flexible-server parameter set -g <group> -s <server> \
#         --name logfiles.download_enable --value on
#     Retention is 1-7 days (server parameter logfiles.retention_days).
#     A few minutes after enabling, the first log becomes available; this
#     script warns (but doesn't stop) if the parameter looks disabled.
#   - `az postgres flexible-server server-logs list` filters by
#     --file-last-written in HOURS (not days), default 72h if unset - this
#     script converts the usual "days back" prompt to hours for you.
#   - `az postgres flexible-server server-logs download` writes files to the
#     CURRENT DIRECTORY using the log's name AS-IS, which per Microsoft's own
#     example can include a folder-style prefix (e.g. "serverlogs/f1.log").
#     This script downloads into DEST_DIR and then flattens that prefix,
#     mirroring how the RDS version strips its "error_" prefix - keep this in
#     mind since it's inferred from documentation, not verified live.
#
# Usage:
#   ./postgres_log_download_from_azure.sh
#   (edit the variables below before running, or export them as env vars to skip the prompts)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------

# Base destination directory for downloaded logs (the server name is
# appended to this path, e.g.: /opt/logs/my-server)
DEST_DIR_BASE="${DEST_DIR_BASE:-/opt/logs}"

# Default number of days back used for the logs' minimum date
# (asked interactively on every run, unless DAYS_BEFORE is already set)
DEFAULT_DAYS_BEFORE=2

# Azure subscription (optional; if empty, uses az's current active subscription)
AZ_SUBSCRIPTION="${AZ_SUBSCRIPTION:-}"

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

command -v az >/dev/null 2>&1 || { echo "Error: az cli not found in PATH." >&2; exit 1; }

AZ_ARGS=()
if [[ -n "$AZ_SUBSCRIPTION" ]]; then
    AZ_ARGS+=(--subscription "$AZ_SUBSCRIPTION")
fi

az account show "${AZ_ARGS[@]+"${AZ_ARGS[@]}"}" >/dev/null 2>&1 || { echo "Error: not logged in to az cli (or subscription not found). Run 'az login' first." >&2; exit 1; }

# ---------------------------------------------------------------------------
# Server selection: dynamically listed from Azure (never hard-coded), in
# alphabetical order, showing the resource group and region next to each
# name. Can be skipped by exporting SERVER_NAME and RESOURCE_GROUP before running.
# ---------------------------------------------------------------------------

SERVER_NAME="${SERVER_NAME:-}"
RESOURCE_GROUP="${RESOURCE_GROUP:-}"
SERVER_REGION=""

if [[ -z "$SERVER_NAME" || -z "$RESOURCE_GROUP" ]]; then
    AVAILABLE_NAMES=()
    AVAILABLE_GROUPS=()
    AVAILABLE_REGIONS=()
    while IFS=$'\t' read -r name rg region; do
        [[ -z "$name" ]] && continue
        AVAILABLE_NAMES+=("$name")
        AVAILABLE_GROUPS+=("$rg")
        AVAILABLE_REGIONS+=("$region")
    done < <(az postgres flexible-server list "${AZ_ARGS[@]+"${AZ_ARGS[@]}"}" \
        --query "sort_by([].{name:name, rg:resourceGroup, region:region}, &name)" \
        --output tsv)

    if [[ "${#AVAILABLE_NAMES[@]}" -eq 0 ]]; then
        echo "Error: no Azure Database for PostgreSQL Flexible Server found in this subscription." >&2
        exit 1
    fi

    echo "Available PostgreSQL Flexible Server instances:"
    for i in "${!AVAILABLE_NAMES[@]}"; do
        printf '%3d) %s (%s, %s)\n' "$((i + 1))" "${AVAILABLE_NAMES[$i]}" "${AVAILABLE_GROUPS[$i]}" "${AVAILABLE_REGIONS[$i]}"
    done

    while : ; do
        read -rp "Choose the instance [1-${#AVAILABLE_NAMES[@]}]: " CHOICE
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#AVAILABLE_NAMES[@]} )); then
            SERVER_NAME="${AVAILABLE_NAMES[$((CHOICE - 1))]}"
            RESOURCE_GROUP="${AVAILABLE_GROUPS[$((CHOICE - 1))]}"
            SERVER_REGION="${AVAILABLE_REGIONS[$((CHOICE - 1))]}"
            break
        else
            echo "Invalid option, try again."
        fi
    done
fi

DEST_DIR="$DEST_DIR_BASE/$SERVER_NAME"
if [[ ! -d "$DEST_DIR" ]]; then
    echo "Destination directory doesn't exist, creating: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# ---------------------------------------------------------------------------
# Warns (without stopping) if log capture for download looks disabled.
# ---------------------------------------------------------------------------

DOWNLOAD_ENABLE=$(az postgres flexible-server parameter show "${AZ_ARGS[@]+"${AZ_ARGS[@]}"}" \
    --resource-group "$RESOURCE_GROUP" --server-name "$SERVER_NAME" \
    --name logfiles.download_enable --query value --output tsv 2>/dev/null || true)

DOWNLOAD_ENABLE_LOWER=$(printf '%s' "$DOWNLOAD_ENABLE" | tr '[:upper:]' '[:lower:]')
if [[ -n "$DOWNLOAD_ENABLE" && "$DOWNLOAD_ENABLE_LOWER" != "on" ]]; then
    echo "Warning: log capture for download (logfiles.download_enable) looks OFF for '$SERVER_NAME'. No logs may be available until it's turned on (az postgres flexible-server parameter set --name logfiles.download_enable --value on)." >&2
fi

# ---------------------------------------------------------------------------
# Minimum log date: asks how many days back to use (default: 2), converted
# to hours for --file-last-written. Can be skipped by exporting DAYS_BEFORE.
# ---------------------------------------------------------------------------

if [[ -z "${DAYS_BEFORE:-}" ]]; then
    read -rp "How many days back for the logs' minimum date? (Enter uses $DEFAULT_DAYS_BEFORE): " DAYS_INPUT
    if [[ -z "$DAYS_INPUT" ]]; then
        DAYS_BEFORE="$DEFAULT_DAYS_BEFORE"
    elif [[ "$DAYS_INPUT" =~ ^[0-9]+$ ]]; then
        DAYS_BEFORE="$DAYS_INPUT"
    else
        echo "Invalid value, using the default of $DEFAULT_DAYS_BEFORE days." >&2
        DAYS_BEFORE="$DEFAULT_DAYS_BEFORE"
    fi
fi

HOURS_BACK=$(( DAYS_BEFORE * 24 ))

echo ""
echo "Server:                  $SERVER_NAME"
echo "Resource group:          $RESOURCE_GROUP"
[[ -n "$SERVER_REGION" ]] && echo "Region:                  $SERVER_REGION"
echo "Destination:             $DEST_DIR"
echo "Minimum date:            last $DAYS_BEFORE day(s) ($HOURS_BACK hours)"
echo ""
echo "Listing available logs..."

# ---------------------------------------------------------------------------
# Lists the log files matching the date filter.
# Fills the parallel arrays ALL_LOG_FILES and ALL_LOG_SIZES (bytes).
# ---------------------------------------------------------------------------

ALL_LOG_FILES=()
ALL_LOG_SIZES=()

while IFS=$'\t' read -r name size_kb; do
    [[ -z "$name" ]] && continue
    size_kb_clean="${size_kb//[^0-9]/}"
    ALL_LOG_FILES+=("$name")
    ALL_LOG_SIZES+=("$(( ${size_kb_clean:-0} * 1024 ))")
done < <(az postgres flexible-server server-logs list "${AZ_ARGS[@]+"${AZ_ARGS[@]}"}" \
    --resource-group "$RESOURCE_GROUP" --server-name "$SERVER_NAME" \
    --file-last-written "$HOURS_BACK" \
    --query "[].[name, sizeInKB]" --output tsv)

TOTAL="${#ALL_LOG_FILES[@]}"

if [[ "$TOTAL" -eq 0 ]]; then
    echo "No logs found in the last $DAYS_BEFORE day(s)."
    exit 0
fi

echo "Total logs to download: $TOTAL"

# Size of a local file in bytes (Linux GNU coreutils or macOS/BSD)
get_file_size() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null || wc -c < "$1"
}

# Available bytes in the given directory (Linux GNU or macOS/BSD df)
get_available_bytes() {
    local avail_kb
    avail_kb=$(df -Pk "$1" | awk 'NR==2 {print $4}')
    echo $(( avail_kb * 1024 ))
}

# Formats bytes into a human-readable unit (B/KB/MB/GB/TB)
format_bytes() {
    awk -v b="$1" 'BEGIN {
        units["1"]="B"; units["2"]="KB"; units["3"]="MB"; units["4"]="GB"; units["5"]="TB"
        i = 1
        while (b >= 1024 && i < 5) { b /= 1024; i++ }
        printf "%.2f %s", b, units[i]
    }'
}

TOTAL_LOG_BYTES=0
for SIZE in "${ALL_LOG_SIZES[@]}"; do
    TOTAL_LOG_BYTES=$((TOTAL_LOG_BYTES + SIZE))
done

AVAILABLE_BYTES=$(get_available_bytes "$DEST_DIR")

echo "Total size of the logs:  $(format_bytes "$TOTAL_LOG_BYTES")"
echo "Available space in $DEST_DIR: $(format_bytes "$AVAILABLE_BYTES")"

if (( TOTAL_LOG_BYTES > AVAILABLE_BYTES )); then
    echo "" >&2
    echo "Error: not enough disk space in $DEST_DIR." >&2
    echo "  Needed:     $(format_bytes "$TOTAL_LOG_BYTES")" >&2
    echo "  Available:  $(format_bytes "$AVAILABLE_BYTES")" >&2
    echo "Download aborted." >&2
    exit 1
fi

echo ""

# ---------------------------------------------------------------------------
# Downloads each log, showing progress. `server-logs download` writes to the
# current directory using the log's name as-is (which may include a
# folder-style prefix), so we run it inside DEST_DIR and then flatten the
# result to a plain filename (same idea as stripping the RDS "error_" prefix).
# ---------------------------------------------------------------------------

CURRENT=0
TOTAL_BYTES=0
LARGEST_BYTES=-1
LARGEST_NAME=""
SMALLEST_BYTES=-1
SMALLEST_NAME=""

for IDX in "${!ALL_LOG_FILES[@]}"; do
    LOG_NAME="${ALL_LOG_FILES[$IDX]}"
    CURRENT=$((CURRENT + 1))
    REMAINING=$((TOTAL - CURRENT))

    echo "[$CURRENT/$TOTAL] Downloading: $LOG_NAME ($REMAINING remaining)"

    (cd "$DEST_DIR" && az postgres flexible-server server-logs download "${AZ_ARGS[@]+"${AZ_ARGS[@]}"}" \
        --resource-group "$RESOURCE_GROUP" --server-name "$SERVER_NAME" --name "$LOG_NAME" >/dev/null)

    DOWNLOADED_PATH="$DEST_DIR/$LOG_NAME"
    LOCAL_FILENAME="${LOG_NAME##*/}"
    LOCAL_PATH="$DEST_DIR/$LOCAL_FILENAME"

    if [[ "$DOWNLOADED_PATH" != "$LOCAL_PATH" && -f "$DOWNLOADED_PATH" ]]; then
        mv "$DOWNLOADED_PATH" "$LOCAL_PATH"
        rmdir -p "$(dirname "$DOWNLOADED_PATH")" 2>/dev/null || true
    fi

    if [[ ! -f "$LOCAL_PATH" ]]; then
        echo "Warning: '$LOG_NAME' wasn't found after download (it may no longer be available on the server)." >&2
        continue
    fi

    FILE_SIZE=$(get_file_size "$LOCAL_PATH")
    TOTAL_BYTES=$((TOTAL_BYTES + FILE_SIZE))

    if (( LARGEST_BYTES < 0 || FILE_SIZE > LARGEST_BYTES )); then
        LARGEST_BYTES="$FILE_SIZE"
        LARGEST_NAME="$LOCAL_FILENAME"
    fi
    if (( SMALLEST_BYTES < 0 || FILE_SIZE < SMALLEST_BYTES )); then
        SMALLEST_BYTES="$FILE_SIZE"
        SMALLEST_NAME="$LOCAL_FILENAME"
    fi
done

AVERAGE_BYTES=$(( TOTAL > 0 ? TOTAL_BYTES / TOTAL : 0 ))

echo ""
echo "Done. Files saved in:    $DEST_DIR"
echo "Files downloaded:        $TOTAL"
echo "Total size:              $(format_bytes "$TOTAL_BYTES")"
echo "Average size per file:   $(format_bytes "$AVERAGE_BYTES")"
echo "Smallest file:           $(format_bytes "$SMALLEST_BYTES") ($SMALLEST_NAME)"
echo "Largest file:            $(format_bytes "$LARGEST_BYTES") ($LARGEST_NAME)"

