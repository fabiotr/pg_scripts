#!/usr/bin/env bash
#
# Downloads PostgreSQL logs from a Google Cloud SQL instance via the gcloud CLI
# (Cloud Logging), filtered by a minimum date.
#
# Requirements: gcloud cli installed and authenticated, with access to
# Cloud SQL Admin and Cloud Logging for the target project.
#
# IMPORTANT ARCHITECTURE DIFFERENCES FROM THE RDS VERSION:
#   - Cloud SQL/Cloud Logging has no per-file log listing like RDS's
#     describe-db-log-files. Logs are a queryable stream of entries, so this
#     script downloads one text file PER DAY instead of per log file.
#   - There is no API that reports exact log size ahead of time. The size
#     shown before downloading is an ESTIMATE (entry count x sampled average
#     entry size), clearly labeled as such - unlike the RDS script's exact
#     size from the API's own Size field.
#   - gcloud's --format=value(...) already extracts plain text client-side,
#     so jq is not required by this script at all (unlike the RDS version,
#     which needs jq to parse JSON unless using a slower text fallback).
#   - Cloud SQL logs are usually in the `textPayload` field. If you've
#     enabled structured PostgreSQL logging, set LOG_PAYLOAD_FIELD=
#     jsonPayload.message instead (see the variable below).
#
# NOTE: Review the log filter and payload field before relying on it in production.
#
# Usage:
#   ./postgres_log_download_from_gcp_sql.sh
#   (edit the variables below before running, or export them as env vars to skip the prompts)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------

# Base destination directory for downloaded logs (the instance name is
# appended to this path, e.g.: /opt/logs/my-instance)
DEST_DIR_BASE="${DEST_DIR_BASE:-/mnt/logs}"

# Default number of days back used for the logs' minimum date
# (asked interactively on every run, unless DAYS_BEFORE is already set)
DEFAULT_DAYS_BEFORE=2

# Number of entries sampled per day to estimate the average entry size
SAMPLE_SIZE="${SAMPLE_SIZE:-20}"

# Field holding the log text. Cloud SQL PostgreSQL logs are usually plain
# text in `textPayload`; if structured logging is enabled, use
# `jsonPayload.message` instead.
LOG_PAYLOAD_FIELD="${LOG_PAYLOAD_FIELD:-textPayload}"

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

command -v gcloud >/dev/null 2>&1 || { echo "Error: gcloud cli not found in PATH." >&2; exit 1; }

# ---------------------------------------------------------------------------
# GCP project
# ---------------------------------------------------------------------------

GCP_PROJECT="${GCP_PROJECT:-}"

if [[ -z "$GCP_PROJECT" ]]; then
    GCP_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
    [[ "$GCP_PROJECT" == "(unset)" ]] && GCP_PROJECT=""
fi

if [[ -z "$GCP_PROJECT" ]]; then
    read -rp "Enter the GCP project id: " GCP_PROJECT
    [[ -n "$GCP_PROJECT" ]] || { echo "Error: project id cannot be empty." >&2; exit 1; }
fi

# ---------------------------------------------------------------------------
# Instance selection: dynamically listed from Cloud SQL (PostgreSQL only,
# never hard-coded), in alphabetical order, showing the region next to each
# name. Can be skipped by exporting INSTANCE_NAME (and optionally
# INSTANCE_REGION) before running.
# ---------------------------------------------------------------------------

INSTANCE_NAME="${INSTANCE_NAME:-}"
INSTANCE_REGION="${INSTANCE_REGION:-}"

if [[ -z "$INSTANCE_NAME" ]]; then
    AVAILABLE_NAMES=()
    AVAILABLE_REGIONS=()
    while IFS=$'\t' read -r name region; do
        [[ -z "$name" ]] && continue
        AVAILABLE_NAMES+=("$name")
        AVAILABLE_REGIONS+=("$region")
    done < <(gcloud sql instances list --project="$GCP_PROJECT" \
        --filter="databaseVersion:POSTGRES*" --format="value(name,region)" | sort -t $'\t' -k1,1)

    if [[ "${#AVAILABLE_NAMES[@]}" -eq 0 ]]; then
        echo "Error: no Cloud SQL PostgreSQL instance found in project '$GCP_PROJECT'." >&2
        exit 1
    fi

    echo "Available PostgreSQL instances in project '$GCP_PROJECT':"
    for i in "${!AVAILABLE_NAMES[@]}"; do
        printf '%3d) %s (%s)\n' "$((i + 1))" "${AVAILABLE_NAMES[$i]}" "${AVAILABLE_REGIONS[$i]}"
    done

    while : ; do
        read -rp "Choose the instance [1-${#AVAILABLE_NAMES[@]}]: " CHOICE
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#AVAILABLE_NAMES[@]} )); then
            INSTANCE_NAME="${AVAILABLE_NAMES[$((CHOICE - 1))]}"
            INSTANCE_REGION="${AVAILABLE_REGIONS[$((CHOICE - 1))]}"
            break
        else
            echo "Invalid option, try again."
        fi
    done
fi

if [[ -z "$INSTANCE_REGION" ]]; then
    INSTANCE_REGION=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$GCP_PROJECT" --format="value(region)")
fi

DEST_DIR="$DEST_DIR_BASE/$INSTANCE_NAME"
if [[ ! -d "$DEST_DIR" ]]; then
    echo "Destination directory doesn't exist, creating: $DEST_DIR"
    mkdir -p "$DEST_DIR"
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

# Next calendar day (YYYY-MM-DD), portable across GNU/BSD date
next_day() {
    date -u -v+1d -jf "%Y-%m-%d" "$1" +%Y-%m-%d 2>/dev/null || date -u -d "$1 + 1 day" +%Y-%m-%d
}

echo ""
echo "Project:                $GCP_PROJECT"
echo "Instance:                $INSTANCE_NAME"
echo "Region:                  $INSTANCE_REGION"
echo "Destination:             $DEST_DIR"
echo "Minimum date:            $MIN_DATE"
echo ""

# ---------------------------------------------------------------------------
# Builds the list of days to download (one log file per day).
# ---------------------------------------------------------------------------

TODAY=$(date -u +%Y-%m-%d)
ALL_DAYS=()
d="$MIN_DATE"
while [[ "$d" < "$TODAY" || "$d" == "$TODAY" ]]; do
    ALL_DAYS+=("$d")
    d=$(next_day "$d")
done

TOTAL="${#ALL_DAYS[@]}"

if [[ "$TOTAL" -eq 0 ]]; then
    echo "No days to process from $MIN_DATE onward."
    exit 0
fi

echo "Total days to download: $TOTAL"

# ---------------------------------------------------------------------------
# Builds the Cloud Logging filter for a single day (UTC boundaries).
# ---------------------------------------------------------------------------

build_day_filter() {
    local day="$1" day_start day_end
    day_start="${day}T00:00:00Z"
    day_end=$(next_day "$day")"T00:00:00Z"
    printf 'resource.type="cloudsql_database" AND resource.labels.database_id="%s:%s" AND logName="projects/%s/logs/cloudsql.googleapis.com%%2Fpostgres.log" AND timestamp>="%s" AND timestamp<"%s"' \
        "$GCP_PROJECT" "$INSTANCE_NAME" "$GCP_PROJECT" "$day_start" "$day_end"
}

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

# ---------------------------------------------------------------------------
# Estimates the total size to download: counts entries per day and samples a
# few to get an average entry size, since Cloud Logging has no API that
# reports exact byte size ahead of time (unlike RDS's Size field).
# ---------------------------------------------------------------------------

echo "Estimating total log size (this queries Cloud Logging, may take a moment)..."

TOTAL_ESTIMATED_BYTES=0
DAY_ENTRY_COUNTS=()

for DAY in "${ALL_DAYS[@]}"; do
    FILTER=$(build_day_filter "$DAY")

    ENTRY_COUNT=$(gcloud logging read "$FILTER" --project="$GCP_PROJECT" \
        --format="value(timestamp)" 2>/dev/null | wc -l | tr -d ' ')
    DAY_ENTRY_COUNTS+=("$ENTRY_COUNT")

    if [[ "$ENTRY_COUNT" -gt 0 ]]; then
        SAMPLE_BYTES=$(gcloud logging read "$FILTER" --project="$GCP_PROJECT" \
            --limit="$SAMPLE_SIZE" --format="value($LOG_PAYLOAD_FIELD)" 2>/dev/null | wc -c | tr -d ' ')
        SAMPLE_COUNT=$(( ENTRY_COUNT < SAMPLE_SIZE ? ENTRY_COUNT : SAMPLE_SIZE ))
        if [[ "$SAMPLE_COUNT" -gt 0 ]]; then
            AVG_ENTRY_BYTES=$(( SAMPLE_BYTES / SAMPLE_COUNT ))
            DAY_ESTIMATED_BYTES=$(( AVG_ENTRY_BYTES * ENTRY_COUNT ))
            TOTAL_ESTIMATED_BYTES=$(( TOTAL_ESTIMATED_BYTES + DAY_ESTIMATED_BYTES ))
        fi
    fi
done

AVAILABLE_BYTES=$(get_available_bytes "$DEST_DIR")

echo "Estimated total size:    $(format_bytes "$TOTAL_ESTIMATED_BYTES") (estimate, not exact)"
echo "Available space in $DEST_DIR: $(format_bytes "$AVAILABLE_BYTES")"

if (( TOTAL_ESTIMATED_BYTES > AVAILABLE_BYTES )); then
    echo "" >&2
    echo "Error: not enough disk space in $DEST_DIR." >&2
    echo "  Estimated needed: $(format_bytes "$TOTAL_ESTIMATED_BYTES")" >&2
    echo "  Available:        $(format_bytes "$AVAILABLE_BYTES")" >&2
    echo "Download aborted." >&2
    exit 1
fi

echo ""

# ---------------------------------------------------------------------------
# Downloads each day's logs, showing progress
# ---------------------------------------------------------------------------

CURRENT=0
TOTAL_BYTES=0
LARGEST_BYTES=-1
LARGEST_NAME=""
SMALLEST_BYTES=-1
SMALLEST_NAME=""

for IDX in "${!ALL_DAYS[@]}"; do
    DAY="${ALL_DAYS[$IDX]}"
    CURRENT=$((CURRENT + 1))
    REMAINING=$((TOTAL - CURRENT))

    LOCAL_FILENAME="postgresql.log.$DAY"
    LOCAL_PATH="$DEST_DIR/$LOCAL_FILENAME"

    echo "[$CURRENT/$TOTAL] Downloading: $DAY (${DAY_ENTRY_COUNTS[$IDX]:-0} entries, $REMAINING remaining)"

    FILTER=$(build_day_filter "$DAY")
    gcloud logging read "$FILTER" --project="$GCP_PROJECT" --order=asc \
        --format="value($LOG_PAYLOAD_FIELD)" > "$LOCAL_PATH"

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

AVERAGE_BYTES=$(( TOTAL_BYTES / TOTAL ))

echo ""
echo "Done. Files saved in:    $DEST_DIR"
echo "Files downloaded:        $TOTAL"
echo "Total size:              $(format_bytes "$TOTAL_BYTES")"
echo "Average size per file:   $(format_bytes "$AVERAGE_BYTES")"
echo "Smallest file:           $(format_bytes "$SMALLEST_BYTES") ($SMALLEST_NAME)"
echo "Largest file:            $(format_bytes "$LARGEST_BYTES") ($LARGEST_NAME)"

