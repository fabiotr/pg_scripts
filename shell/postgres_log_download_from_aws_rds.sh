#!/usr/bin/env bash
#
# Downloads log files from an RDS instance via the AWS CLI, filtered by a minimum date.
#
# Requirements: aws cli configured (credentials/region).
# jq is optional: if not installed, the script warns and falls back to an
# alternative path (via the aws cli's own --query/--output text) for downloads.
#
# Usage:
#   ./postgres_log_download_from_aws_rds.sh
#   (edit the variables below before running, or export them as env vars to skip the prompts)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------

# Base destination directory for downloaded logs (the chosen service/instance
# name is appended to this path, e.g.: /opt/logs/prd_eu)
DEST_DIR_BASE="${DEST_DIR_BASE:-/mnt/logs}"

# Default number of days back used for the logs' minimum date
# (asked interactively on every run, unless DAYS_BEFORE is already set)
DEFAULT_DAYS_BEFORE=2

# AWS region (optional; if empty, uses the aws cli's default configuration)
AWS_REGION="${AWS_REGION:-}"

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

command -v aws >/dev/null 2>&1 || { echo "Error: aws cli not found in PATH." >&2; exit 1; }

HAVE_JQ=true
if ! command -v jq >/dev/null 2>&1; then
    HAVE_JQ=false
    echo "Warning: jq not found in PATH. Continuing without jq (slower fallback path)." >&2
fi

# ---------------------------------------------------------------------------
# Locates the pg_service file, following the same precedence order as libpq:
#   1) PGSERVICEFILE environment variable
#   2) ~/.pg_service.conf
#   3) <pg_config --sysconfdir>/pg_service.conf
# ---------------------------------------------------------------------------

PG_SERVICE_FILE=""

if [[ -n "${PGSERVICEFILE:-}" ]]; then
    if [[ -f "$PGSERVICEFILE" ]]; then
        PG_SERVICE_FILE="$PGSERVICEFILE"
    fi
elif [[ -f "$HOME/.pg_service.conf" ]]; then
    PG_SERVICE_FILE="$HOME/.pg_service.conf"
elif command -v pg_config >/dev/null 2>&1; then
    SYSCONFDIR=$(pg_config --sysconfdir 2>/dev/null || true)
    if [[ -n "$SYSCONFDIR" && -f "$SYSCONFDIR/pg_service.conf" ]]; then
        PG_SERVICE_FILE="$SYSCONFDIR/pg_service.conf"
    fi
fi

# ---------------------------------------------------------------------------
# Extracts the host= value from inside the [SERVICE_NAME] section of pg_service.conf
# ---------------------------------------------------------------------------

get_service_host() {
    awk -v section="$2" '
        /^\[/ { insection = ($0 == "["section"]"); next }
        insection && $0 ~ /^[[:space:]]*host[[:space:]]*=/ {
            sub(/^[[:space:]]*host[[:space:]]*=[[:space:]]*/, "")
            sub(/[[:space:]]+$/, "")
            print
            exit
        }
    ' "$1"
}

# Extracts the region from an RDS hostname: the part before ".rds.amazonaws.com",
# or, in the AWS China partition, before ".amazonaws.com.cn" (only if it starts
# with "cn"). Prints the region found, or nothing if it can't be extracted.
extract_region_from_host() {
    local host="$1" prefix candidate
    if [[ "$host" == *.rds.amazonaws.com ]]; then
        prefix="${host%.rds.amazonaws.com}"
        echo "${prefix##*.}"
    elif [[ "$host" == *.amazonaws.com.cn ]]; then
        prefix="${host%.amazonaws.com.cn}"
        candidate="${prefix##*.}"
        [[ "$candidate" == cn* ]] && echo "$candidate"
    fi
}

# ---------------------------------------------------------------------------
# If a pg_service.conf was found, builds the list of services in alphabetical
# order (always read fresh, never hard-coded in the script), showing next to
# each one the db_instance_identifier extracted from its host. Services whose
# host is a VPC endpoint (not a direct RDS endpoint) are omitted from the list.
# Asks the user to pick one by number; if PGSERVICE is set and is a valid
# service, it becomes the default (Enter accepts it). If no pg_service exists,
# the db_instance_identifier is asked for manually further below.
# ---------------------------------------------------------------------------

SERVICE_NAME="${SERVICE_NAME:-}"
SERVICE_HOST=""

if [[ -z "$SERVICE_NAME" && -n "$PG_SERVICE_FILE" ]]; then
    mapfile -t RAW_SERVICES < <(grep -E '^\[[^]]+\]$' "$PG_SERVICE_FILE" | sed -E 's/^\[(.*)\]$/\1/')

    SERVICE_ROWS=""
    for svc in "${RAW_SERVICES[@]}"; do
        host=$(get_service_host "$PG_SERVICE_FILE" "$svc")
        [[ -z "$host" ]] && continue
        [[ "$host" == *.vpce.amazonaws.com ]] && continue
        id="${host%%.*}"
        SERVICE_ROWS+="$svc"$'\t'"$id"$'\t'"$host"$'\n'
    done

    AVAILABLE_SERVICES=()
    AVAILABLE_IDS=()
    AVAILABLE_HOSTS=()
    if [[ -n "$SERVICE_ROWS" ]]; then
        while IFS=$'\t' read -r svc id host; do
            [[ -z "$svc" ]] && continue
            AVAILABLE_SERVICES+=("$svc")
            AVAILABLE_IDS+=("$id")
            AVAILABLE_HOSTS+=("$host")
        done < <(printf '%s' "$SERVICE_ROWS" | sort -t $'\t' -k1,1)
    fi

    if [[ "${#AVAILABLE_SERVICES[@]}" -eq 0 ]]; then
        echo "Warning: no service with a valid RDS host found in $PG_SERVICE_FILE." >&2
        PG_SERVICE_FILE=""
    else
        DEFAULT_INDEX=""
        if [[ -n "${PGSERVICE:-}" ]]; then
            for i in "${!AVAILABLE_SERVICES[@]}"; do
                if [[ "${AVAILABLE_SERVICES[$i]}" == "$PGSERVICE" ]]; then
                    DEFAULT_INDEX="$i"
                    break
                fi
            done
        fi

        echo "Available instances (from $PG_SERVICE_FILE):"
        for i in "${!AVAILABLE_SERVICES[@]}"; do
            printf '%3d) %s (%s)\n' "$((i + 1))" "${AVAILABLE_SERVICES[$i]}" "${AVAILABLE_IDS[$i]}"
        done

        PROMPT="Choose the instance [1-${#AVAILABLE_SERVICES[@]}]"
        [[ -n "$DEFAULT_INDEX" ]] && PROMPT+=" (Enter uses PGSERVICE=${AVAILABLE_SERVICES[$DEFAULT_INDEX]})"
        PROMPT+=": "

        while : ; do
            read -rp "$PROMPT" CHOICE
            [[ -z "$CHOICE" && -n "$DEFAULT_INDEX" ]] && CHOICE=$((DEFAULT_INDEX + 1))

            if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#AVAILABLE_SERVICES[@]} )); then
                SERVICE_NAME="${AVAILABLE_SERVICES[$((CHOICE - 1))]}"
                SERVICE_HOST="${AVAILABLE_HOSTS[$((CHOICE - 1))]}"
                break
            else
                echo "Invalid option, try again."
            fi
        done
    fi
fi

if [[ -z "$SERVICE_NAME" && -z "$PG_SERVICE_FILE" ]]; then
    echo "No pg_service file found (PGSERVICEFILE, ~/.pg_service.conf, or \$(pg_config --sysconfdir)/pg_service.conf)."
fi

# ---------------------------------------------------------------------------
# Real RDS instance/cluster identifier and region, extracted from the host:
#   - identifier = first part of the host, before the first dot
#   - region     = part of the host right before ".rds.amazonaws.com"
#     (or, in the AWS China partition, before ".amazonaws.com.cn", provided
#     the extracted value starts with "cn")
# ---------------------------------------------------------------------------

if [[ -z "${DB_INSTANCE_IDENTIFIER:-}" && -n "$SERVICE_NAME" ]]; then
    if [[ -z "$SERVICE_HOST" ]]; then
        SERVICE_HOST=$(get_service_host "$PG_SERVICE_FILE" "$SERVICE_NAME")
        if [[ "$SERVICE_HOST" == *.vpce.amazonaws.com ]]; then
            echo "Warning: the host for '$SERVICE_NAME' looks like a VPC endpoint, not a direct RDS endpoint. The extracted db_instance_identifier may be wrong." >&2
        fi
    fi

    if [[ -n "$SERVICE_HOST" ]]; then
        DB_INSTANCE_IDENTIFIER="${SERVICE_HOST%%.*}"

        if [[ -z "${AWS_REGION:-}" ]]; then
            AWS_REGION=$(extract_region_from_host "$SERVICE_HOST")
            if [[ -z "$AWS_REGION" ]]; then
                echo "Warning: could not extract the region from host '$SERVICE_HOST' (doesn't end in .rds.amazonaws.com or .amazonaws.com.cn with a 'cn*' region). Using the aws cli's default configured region." >&2
            fi
        fi

        echo "Host (pg_service):     $SERVICE_HOST"
        echo "  -> db_instance_identifier: $DB_INSTANCE_IDENTIFIER"
        [[ -n "$AWS_REGION" ]] && echo "  -> region:                 $AWS_REGION"
    else
        echo "Warning: couldn't find a 'host' for service '$SERVICE_NAME' in $PG_SERVICE_FILE." >&2
    fi
fi

# ---------------------------------------------------------------------------
# No pg_service.conf: before asking for the db_instance_identifier manually,
# try using the PGHOST environment variable as a default value, extracting
# the identifier and region from it (same logic used for the pg_service host).
# ---------------------------------------------------------------------------

if [[ -z "${DB_INSTANCE_IDENTIFIER:-}" ]]; then
    DEFAULT_ID_FROM_PGHOST=""

    if [[ -n "${PGHOST:-}" ]]; then
        DEFAULT_ID_FROM_PGHOST="${PGHOST%%.*}"

        if [[ -z "${AWS_REGION:-}" ]]; then
            AWS_REGION=$(extract_region_from_host "$PGHOST")
            if [[ -z "$AWS_REGION" ]]; then
                echo "Warning: could not extract the region from PGHOST='$PGHOST' (doesn't end in .rds.amazonaws.com or .amazonaws.com.cn with a 'cn*' region). Using the aws cli's default configured region." >&2
            fi
        fi

        echo "PGHOST detected:        $PGHOST"
        echo "  -> db_instance_identifier: $DEFAULT_ID_FROM_PGHOST"
        [[ -n "$AWS_REGION" ]] && echo "  -> region:                 $AWS_REGION"
    fi

    if [[ -n "$DEFAULT_ID_FROM_PGHOST" ]]; then
        read -rp "Enter the db_instance_identifier (Enter uses '$DEFAULT_ID_FROM_PGHOST', extracted from PGHOST): " INPUT_ID
        DB_INSTANCE_IDENTIFIER="${INPUT_ID:-$DEFAULT_ID_FROM_PGHOST}"
    else
        read -rp "Enter the db_instance_identifier manually: " DB_INSTANCE_IDENTIFIER
    fi

    [[ -n "$DB_INSTANCE_IDENTIFIER" ]] || { echo "Error: db_instance_identifier cannot be empty." >&2; exit 1; }
fi

DEST_DIR="$DEST_DIR_BASE/${SERVICE_NAME:-$DB_INSTANCE_IDENTIFIER}"

AWS_ARGS=(--db-instance-identifier "$DB_INSTANCE_IDENTIFIER")
if [[ -n "$AWS_REGION" ]]; then
    AWS_ARGS+=(--region "$AWS_REGION")
fi

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

# Converts MIN_DATE (YYYY-MM-DD) to epoch milliseconds (format required by the API filter)
if date -u -d "$MIN_DATE" +%s >/dev/null 2>&1; then
    MIN_DATE_EPOCH_MS=$(( $(date -u -d "$MIN_DATE" +%s) * 1000 ))
else
    # macOS/BSD date
    MIN_DATE_EPOCH_MS=$(( $(date -u -j -f "%Y-%m-%d" "$MIN_DATE" +%s) * 1000 ))
fi

echo ""
[[ -n "$SERVICE_NAME" ]] && echo "Service (pg_service):  $SERVICE_NAME"
echo "RDS instance:           $DB_INSTANCE_IDENTIFIER"
echo "Destination:            $DEST_DIR"
echo "Minimum date:           $MIN_DATE"
echo ""
echo "Listing available logs..."

# ---------------------------------------------------------------------------
# Lists the log files matching the date filter (with pagination).
# Fills the global arrays ALL_LOG_FILES and ALL_LOG_SIZES (bytes, paired by index).
# ---------------------------------------------------------------------------

list_log_files() {
    ALL_LOG_FILES=()
    ALL_LOG_SIZES=()
    local marker="" call_args page name size size_clean

    while : ; do
        call_args=("${AWS_ARGS[@]}" --file-last-written "$MIN_DATE_EPOCH_MS")
        [[ -n "$marker" ]] && call_args+=(--marker "$marker")

        if [[ "$HAVE_JQ" == "true" ]]; then
            page=$(aws rds describe-db-log-files "${call_args[@]}" --output json)
            while IFS=$'\t' read -r name size; do
                [[ -n "$name" ]] || continue
                size_clean="${size//[^0-9]/}"
                ALL_LOG_FILES+=("$name")
                ALL_LOG_SIZES+=("${size_clean:-0}")
            done < <(echo "$page" | jq -r '.DescribeDBLogFiles[] | "\(.LogFileName)\t\(.Size)"')
            marker=$(echo "$page" | jq -r '.Marker // empty')
        else
            while IFS=$'\t' read -r name size; do
                [[ -n "$name" ]] || continue
                size_clean="${size//[^0-9]/}"
                ALL_LOG_FILES+=("$name")
                ALL_LOG_SIZES+=("${size_clean:-0}")
            done < <(aws rds describe-db-log-files "${call_args[@]}" \
                --query 'DescribeDBLogFiles[].[LogFileName,Size]' --output text)
            marker=$(aws rds describe-db-log-files "${call_args[@]}" --query 'Marker' --output text)
            [[ "$marker" == "None" ]] && marker=""
        fi

        [[ -z "$marker" ]] && break
    done
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

list_log_files

TOTAL="${#ALL_LOG_FILES[@]}"

if [[ "$TOTAL" -eq 0 ]]; then
    echo "No logs found from $MIN_DATE onward."
    exit 0
fi

echo "Total logs to download: $TOTAL"

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
# Downloads a single log, paginating via Marker/AdditionalDataPending until done.
# ---------------------------------------------------------------------------

download_log_file() {
    local log_name="$1" local_path="$2"
    local marker="0" call_args portion data additional additional_lower meta

    : > "$local_path"

    while : ; do
        call_args=("${AWS_ARGS[@]}" --log-file-name "$log_name" --marker "$marker")

        if [[ "$HAVE_JQ" == "true" ]]; then
            portion=$(aws rds download-db-log-file-portion "${call_args[@]}" --output json)
            echo "$portion" | jq -r '.LogFileData' >> "$local_path"
            additional=$(echo "$portion" | jq -r '.AdditionalDataPending')
            marker=$(echo "$portion" | jq -r '.Marker')
        else
            data=$(aws rds download-db-log-file-portion "${call_args[@]}" --query 'LogFileData' --output text)
            [[ "$data" != "None" ]] && printf '%s\n' "$data" >> "$local_path"

            meta=$(aws rds download-db-log-file-portion "${call_args[@]}" --query '[Marker,AdditionalDataPending]' --output text)
            marker=$(printf '%s' "$meta" | cut -f1)
            additional=$(printf '%s' "$meta" | cut -f2)
        fi

        additional_lower=$(printf '%s' "$additional" | tr '[:upper:]' '[:lower:]')
        [[ "$additional_lower" != "true" ]] && break
    done
}

# ---------------------------------------------------------------------------
# Downloads each log, showing progress
# ---------------------------------------------------------------------------

CURRENT=0
TOTAL_BYTES=0
LARGEST_BYTES=-1
LARGEST_NAME=""
SMALLEST_BYTES=-1
SMALLEST_NAME=""

for LOG_NAME in "${ALL_LOG_FILES[@]}"; do
    CURRENT=$((CURRENT + 1))
    REMAINING=$((TOTAL - CURRENT))

    LOCAL_FILENAME="${LOG_NAME//\//_}"
    LOCAL_FILENAME="${LOCAL_FILENAME#error_}"
    LOCAL_PATH="$DEST_DIR/$LOCAL_FILENAME"
    mkdir -p "$(dirname "$LOCAL_PATH")"

    echo "[$CURRENT/$TOTAL] Downloading: $LOG_NAME ($REMAINING remaining)"

    download_log_file "$LOG_NAME" "$LOCAL_PATH"

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
