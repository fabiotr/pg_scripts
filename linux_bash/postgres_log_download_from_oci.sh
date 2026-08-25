#!/usr/bin/env bash
#
# Downloads PostgreSQL logs from an OCI Database with PostgreSQL DB system
# via the OCI CLI, filtered by a minimum date. 
#
# Requirements: oci cli installed and configured (`oci setup config`), with
# access to the target compartment, the PostgreSQL DB system, and the Object
# Storage bucket the logs are exported to.
#
# IMPORTANT ARCHITECTURE DIFFERENCES / PREREQUISITES:
#   - OCI Database with PostgreSQL does NOT expose a "list/download log
#     files" API by itself. Logs must first be explicitly configured (via a
#     DB system configuration) to export to Object Storage:
#       oci.log_destination = oci_object_storage
#       oci.log_destination_os_namespace = <tenancy Object Storage namespace>
#       oci.log_destination_os_bucket_name = <bucket name>
#     This script does NOT set that up for you - it only reads what's
#     already been exported. If the bucket is empty, check that config first.
#   - Once exported, log objects follow this naming pattern (per Oracle's
#     docs): <DB_SYSTEM_OCID>/<DB_INSTANCE_OCID>/postgresql-<DATE>_NNNNNN.csv.gz
#     This script filters by the <DATE> embedded in the object name (not a
#     separate timestamp field, to sidestep uncertainty about exact JSON
#     field names/casing - see note below).
#   - Logs are exported as gzip-compressed CSV (not plain-text postgres.log).
#     Set DECOMPRESS=true to gunzip them after download.
#   - The OCI CLI only supports --output json/table (no text/tsv like AWS or
#     Azure), so this script uses a documented JMESPath trick instead of jq:
#     --query 'data[*].join(`\t`, [...]) | join(`\n`, @)' --raw-output
#
# Usage:
#   ./postgres_log_download_from_oci.sh
#   (edit the variables below before running, or export them as env vars to skip the prompts)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------

# Base destination directory for downloaded logs (the DB system name is
# appended to this path, e.g.: /mnt/logs/my-db-system)
DEST_DIR_BASE="${DEST_DIR_BASE:-/mnt/logs}"

# Default number of days back used for the logs' minimum date
# (asked interactively on every run, unless DAYS_BEFORE is already set)
DEFAULT_DAYS_BEFORE=2

# Gunzip each .csv.gz after downloading (replaces the .gz with the plain file)
DECOMPRESS="${DECOMPRESS:-false}"

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

command -v oci >/dev/null 2>&1 || { echo "Error: oci cli not found in PATH." >&2; exit 1; }

# ---------------------------------------------------------------------------
# Compartment (OCI has no single global "project" like GCP; the compartment
# tree makes auto-discovery unreliable, so this is always asked/required).
# ---------------------------------------------------------------------------

COMPARTMENT_ID="${COMPARTMENT_ID:-}"
if [[ -z "$COMPARTMENT_ID" ]]; then
    read -rp "Enter the compartment OCID: " COMPARTMENT_ID
    [[ -n "$COMPARTMENT_ID" ]] || { echo "Error: compartment OCID cannot be empty." >&2; exit 1; }
fi

# ---------------------------------------------------------------------------
# DB system selection: dynamically listed from OCI (never hard-coded), in
# alphabetical order. Can be skipped by exporting DB_SYSTEM_ID (and
# optionally DB_SYSTEM_NAME) before running.
# ---------------------------------------------------------------------------

DB_SYSTEM_ID="${DB_SYSTEM_ID:-}"
DB_SYSTEM_NAME="${DB_SYSTEM_NAME:-}"

if [[ -z "$DB_SYSTEM_ID" ]]; then
    AVAILABLE_IDS=()
    AVAILABLE_NAMES=()
    while IFS=$'\t' read -r id name; do
        [[ -z "$id" ]] && continue
        AVAILABLE_IDS+=("$id")
        AVAILABLE_NAMES+=("$name")
    done < <(oci psql db-system-collection list-db-systems --compartment-id "$COMPARTMENT_ID" --all \
        --query 'sort_by(data.items, &"display-name")[*].join(`\t`, [id, "display-name"]) | join(`\n`, @)' \
        --raw-output 2>/dev/null)

    if [[ "${#AVAILABLE_IDS[@]}" -eq 0 ]]; then
        echo "Error: no PostgreSQL DB system found in compartment '$COMPARTMENT_ID'." >&2
        exit 1
    fi

    echo "Available PostgreSQL DB systems:"
    for i in "${!AVAILABLE_IDS[@]}"; do
        printf '%3d) %s (%s)\n' "$((i + 1))" "${AVAILABLE_NAMES[$i]}" "${AVAILABLE_IDS[$i]}"
    done

    while : ; do
        read -rp "Choose the DB system [1-${#AVAILABLE_IDS[@]}]: " CHOICE
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#AVAILABLE_IDS[@]} )); then
            DB_SYSTEM_ID="${AVAILABLE_IDS[$((CHOICE - 1))]}"
            DB_SYSTEM_NAME="${AVAILABLE_NAMES[$((CHOICE - 1))]}"
            break
        else
            echo "Invalid option, try again."
        fi
    done
fi

DEST_DIR="$DEST_DIR_BASE/${DB_SYSTEM_NAME:-$DB_SYSTEM_ID}"
if [[ ! -d "$DEST_DIR" ]]; then
    echo "Destination directory doesn't exist, creating: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# ---------------------------------------------------------------------------
# Object Storage bucket holding the exported logs. There's no reliable way
# to auto-detect this from the DB system (would need to read back its
# applied configuration, whose exact CLI/JSON shape wasn't confirmed while
# writing this script), so it's always asked/required.
# ---------------------------------------------------------------------------

BUCKET_NAME="${BUCKET_NAME:-}"
if [[ -z "$BUCKET_NAME" ]]; then
    read -rp "Enter the Object Storage bucket name where logs are exported: " BUCKET_NAME
    [[ -n "$BUCKET_NAME" ]] || { echo "Error: bucket name cannot be empty." >&2; exit 1; }
fi

NAMESPACE_NAME="${NAMESPACE_NAME:-}"
if [[ -z "$NAMESPACE_NAME" ]]; then
    NAMESPACE_NAME=$(oci os ns get --query data --raw-output 2>/dev/null || true)
    [[ -z "$NAMESPACE_NAME" ]] && { echo "Error: could not resolve the Object Storage namespace (oci os ns get). Set NAMESPACE_NAME manually." >&2; exit 1; }
fi

# ---------------------------------------------------------------------------
# Minimum log date: asks how many days back to use (default: 2).
# Can be skipped by exporting DAYS_BEFORE or MIN_DATE (YYYY-MM-DD) before running.
# ---------------------------------------------------------------------------

if [[ -z "${MIN_DATE:-}" ]]; then
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
    MIN_DATE=$(date -u -v-"${DAYS_BEFORE}"d +%Y-%m-%d 2>/dev/null || date -u -d "$DAYS_BEFORE days ago" +%Y-%m-%d)
fi

echo ""
echo "DB system:               ${DB_SYSTEM_NAME:-$DB_SYSTEM_ID}"
echo "Compartment:             $COMPARTMENT_ID"
echo "Bucket:                  $BUCKET_NAME (namespace: $NAMESPACE_NAME)"
echo "Destination:             $DEST_DIR"
echo "Minimum date:            $MIN_DATE"
echo ""
echo "Listing available logs..."

# ---------------------------------------------------------------------------
# Lists log objects under the DB system's prefix, then filters by the date
# embedded in the object name (postgresql-YYYY-MM-DD_NNNNNN.csv.gz), since
# relying on a specific timestamp field name/format wasn't confirmed live.
# Fills the parallel arrays ALL_LOG_FILES and ALL_LOG_SIZES (bytes).
# ---------------------------------------------------------------------------

ALL_LOG_FILES=()
ALL_LOG_SIZES=()
UNPARSED_COUNT=0

while IFS=$'\t' read -r name size; do
    [[ -z "$name" ]] && continue
    size_clean="${size//[^0-9]/}"

    if [[ "$name" =~ postgresql-([0-9]{4}-[0-9]{2}-[0-9]{2})_ ]]; then
        obj_date="${BASH_REMATCH[1]}"
        if [[ "$obj_date" < "$MIN_DATE" ]]; then
            continue
        fi
    else
        UNPARSED_COUNT=$((UNPARSED_COUNT + 1))
    fi

    ALL_LOG_FILES+=("$name")
    ALL_LOG_SIZES+=("${size_clean:-0}")
done < <(oci os object list --bucket-name "$BUCKET_NAME" --namespace-name "$NAMESPACE_NAME" \
    --prefix "$DB_SYSTEM_ID/" --all \
    --query 'data[*].join(`\t`, [name, to_string(size)]) | join(`\n`, @)' \
    --raw-output 2>/dev/null)

TOTAL="${#ALL_LOG_FILES[@]}"

if [[ "$TOTAL" -eq 0 ]]; then
    echo "No logs found from $MIN_DATE onward under prefix '$DB_SYSTEM_ID/' in bucket '$BUCKET_NAME'."
    echo "If this is unexpected, confirm log export to Object Storage is configured for this DB system (oci.log_destination = oci_object_storage)."
    exit 0
fi

[[ "$UNPARSED_COUNT" -gt 0 ]] && echo "Warning: $UNPARSED_COUNT object name(s) didn't match the expected postgresql-YYYY-MM-DD_NNNNNN.csv.gz pattern; included anyway (date filter couldn't be applied to them)." >&2

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
# Downloads each log, showing progress. Object names look like
# <DB_SYSTEM_OCID>/<DB_INSTANCE_OCID>/postgresql-<DATE>_NNNNNN.csv.gz; the
# local filename drops the (repetitive, per-run-constant) DB system OCID and
# replaces the instance OCID with a short "nodeN" label assigned in order of
# first appearance, to keep names readable while still avoiding collisions
# when a DB system has more than one instance exporting logs.
# ---------------------------------------------------------------------------

KNOWN_INSTANCE_IDS=()
KNOWN_INSTANCE_LABELS=()

# Sets LABEL_RESULT for the given instance id. Must be called directly (not
# via command substitution), since it mutates the KNOWN_INSTANCE_* arrays -
# `$(label_for_instance ...)` would run it in a subshell and silently lose
# those updates, handing out "node1" for every instance.
label_for_instance() {
    local instance_id="$1"
    local i
    for i in "${!KNOWN_INSTANCE_IDS[@]}"; do
        if [[ "${KNOWN_INSTANCE_IDS[$i]}" == "$instance_id" ]]; then
            LABEL_RESULT="${KNOWN_INSTANCE_LABELS[$i]}"
            return
        fi
    done
    LABEL_RESULT="node$(( ${#KNOWN_INSTANCE_IDS[@]} + 1 ))"
    KNOWN_INSTANCE_IDS+=("$instance_id")
    KNOWN_INSTANCE_LABELS+=("$LABEL_RESULT")
}

CURRENT=0
TOTAL_BYTES=0
LARGEST_BYTES=-1
LARGEST_NAME=""
SMALLEST_BYTES=-1
SMALLEST_NAME=""

for OBJ_NAME in "${ALL_LOG_FILES[@]}"; do
    CURRENT=$((CURRENT + 1))
    REMAINING=$((TOTAL - CURRENT))

    INSTANCE_ID="${OBJ_NAME#*/}"
    INSTANCE_ID="${INSTANCE_ID%%/*}"
    BASENAME="${OBJ_NAME##*/}"
    label_for_instance "$INSTANCE_ID"
    LOCAL_FILENAME="${LABEL_RESULT}_${BASENAME}"
    LOCAL_PATH="$DEST_DIR/$LOCAL_FILENAME"

    echo "[$CURRENT/$TOTAL] Downloading: $OBJ_NAME ($REMAINING remaining)"

    oci os object get --bucket-name "$BUCKET_NAME" --namespace-name "$NAMESPACE_NAME" \
        --name "$OBJ_NAME" --file "$LOCAL_PATH" >/dev/null

    if [[ "$DECOMPRESS" == "true" && "$LOCAL_PATH" == *.gz ]]; then
        gunzip -f "$LOCAL_PATH"
        LOCAL_PATH="${LOCAL_PATH%.gz}"
        LOCAL_FILENAME="${LOCAL_FILENAME%.gz}"
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

