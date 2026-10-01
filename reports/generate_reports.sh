#!/usr/bin/env bash
# Generic PostgreSQL health-check report generator (cluster + database),
# driven by pg_service.conf entries. No environment-specific defaults —
# every cluster/service list, label and timeout is passed in via flags or
# env vars.
#
# The database used for "database" kind reports is picked per service, in
# this order:
#   1. The config file's dbname column for that service (-c/--config).
#   2. -n/--default-dbname, if given (applies to every service without a
#      config-file entry).
#   3. Auto-detected by connecting to the service (its pg_service.conf
#      default database) and picking, in order of preference: the
#      database with the highest pg_stat_statements load if that
#      extension is installed, otherwise the largest database by size.
#
# Layout expected (this repo's reports/ + sql/ split):
#   reports/generate_reports.sh   <- this file
#   reports/report_cluster.sql    <- found next to this script, always
#   reports/report_database.sql   <- found next to this script, always
#   reports/normalize_md.py       <- found via --normalize-script, see below
#                                     (not needed with --format raw)
#   sql/*.sql                     <- fragment library \ir'd by report_*.sql,
#                                     found via --scripts-dir, see below
#
# report_cluster.sql/report_database.sql \ir a chain of fragments (relative
# names); this script cds into their own directory and invokes them via a
# bare relative filename so psql's \ir tracks "." as their base directory,
# then passes -v sql_dir=<--scripts-dir> so their leading `\cd :sql_dir`
# retargets every subsequent \ir at the fragment library in sql/.
#
# Usage:
#   generate_reports.sh [options] [service ...]
#
# If no service is given on the command line (and REPORT_SERVICES is also
# unset), the services listed in the config file (-c/--config, see below)
# are used instead, in file order. It's an error to omit services with no
# config file to fall back to.
#
# --localhost ignores services entirely (CLI args, REPORT_SERVICES, and the
# config file's service list) and connects to the local PostgreSQL instead
# (no service=/host=, just whatever psql's own defaults resolve to — the
# local Unix socket in the common case). The machine's hostname is used in
# place of the service name in the output filename; -n/--default-dbname
# and dbname auto-detection still apply for "database" kind reports (the
# config file's per-service label/dbname/timeout columns do not, since
# there's no service to look them up by).
#
# Options (all have REPORT_* env var equivalents, flags win):
#   -d, --scripts-dir DIR   Dir with the sql/ fragment library (variables.sql,
#                           internal.sql, ...). Default: ../sql next to this
#                           script (the repo's own sql/).
#   -m, --normalize-script FILE|DIR  Path to normalize_md.py, or a directory
#                           containing it. Default: this script's directory.
#   -o, --out-dir DIR       Base output directory. Default: $HOME/reports.
#   -k, --kinds LIST        Comma-separated report kinds. Default:
#                           cluster,database.
#   -c, --config FILE       File, lines "service label dbname stmt_timeout
#                           total_timeout [kind]", used for:
#                             - label: renames the output file (label =
#                               service when a service has no entry).
#                             - dbname: picks the database "database" kind
#                               reports connect to for that service (see
#                               the priority order above).
#                             - stmt_timeout/total_timeout: override
#                               -t/--stmt-timeout and -T/--total-timeout
#                               for that service. kind defaults to "*"
#                               (both); give the same service two lines
#                               with different kinds for different
#                               cluster vs. database timeouts.
#                           Also doubles as the service list when none is
#                           given on the command line (services used in
#                           file order). Use "-" (or omit trailing columns)
#                           to skip just one column while still setting
#                           others on the same line. Default: report.conf
#                           next to this script (git-ignored; see
#                           report.conf.example) if it exists, otherwise
#                           nothing is loaded/overridden.
#   -n, --default-dbname NAME  Fallback database for "database" kind
#                           reports, for any service without a config-file
#                           dbname (see the priority order above). No
#                           default — omit it to auto-detect instead.
#   -f, --format FMT        Output format. Default: md.
#                             md      - Markdown, psql tables converted to
#                                       Markdown tables (.md).
#                             md-code - Markdown, but psql tables kept
#                                       as-is (aligned columns) inside
#                                       fenced code blocks (.md). Much
#                                       lighter to render in Notion for
#                                       big reports with many tables.
#                             raw     - psql output as printed, no
#                                       Markdown conversion (.txt). Only
#                                       psql's own \timing/\pset status
#                                       lines ("Timing is on." ...) are
#                                       dropped, as in the other formats.
#   -t, --stmt-timeout DUR  Default statement_timeout. Default: 300s.
#   -T, --total-timeout SEC Default per-report wall clock timeout (secs).
#                           Default: 600.
#   -C, --connect-timeout SEC  libpq connect_timeout for every connection.
#                           Default: 60.
#   -r, --connect-retries N Extra attempts when a report can't connect at all
#                           (psql exit code 2), for links that drop a
#                           connection now and then. Before each report a
#                           "SELECT 1" connection is tried up to 1 + N times,
#                           --connect-retry-delay seconds apart; a
#                           report that already started is never re-run, and
#                           SQL errors or timeouts are not retried. Each
#                           retry prints a RETRY line. 0 disables it.
#                           Default: 2.
#   --connect-retry-delay SEC  Seconds to wait between those connection
#                           attempts. Default: 2.
#   --localhost             Ignore all services and connect to the local
#                           PostgreSQL instead (see above). The machine's
#                           hostname replaces the service name in the
#                           output filename.
#   -h, --help              Show this help and exit.
#
# Env var equivalents: REPORT_SCRIPTS_DIR, REPORT_NORMALIZE_SCRIPT,
# REPORT_OUT_DIR, REPORT_KINDS, REPORT_CONFIG_FILE, REPORT_DEFAULT_DBNAME,
# REPORT_FORMAT, REPORT_STMT_TIMEOUT, REPORT_TOTAL_TIMEOUT,
# REPORT_CONNECT_TIMEOUT, REPORT_CONNECT_RETRIES, REPORT_CONNECT_RETRY_DELAY,
# REPORT_SERVICES (space/comma separated, used when no service is given on
# the command line).
#
# Output: <out-dir>/YYYY-MM-DD/YYYY-MM-DD_<label>_<kind>.md (.txt with
# --format raw)
set -uo pipefail

SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

SCRIPTS_DIR="${REPORT_SCRIPTS_DIR:-$(dirname -- "$SELF_DIR")/sql}"
NORMALIZE_SCRIPT="${REPORT_NORMALIZE_SCRIPT:-$SELF_DIR}"
OUT_BASE="${REPORT_OUT_DIR:-$HOME/reports}"
KINDS="${REPORT_KINDS:-cluster,database}"
CONFIG_FILE="${REPORT_CONFIG_FILE:-}"
CONFIG_FILE_IS_DEFAULT=1
[[ -n "$CONFIG_FILE" ]] && CONFIG_FILE_IS_DEFAULT=0
DEFAULT_DBNAME="${REPORT_DEFAULT_DBNAME:-}"
FORMAT="${REPORT_FORMAT:-md}"
STMT_TIMEOUT="${REPORT_STMT_TIMEOUT:-300s}"
TOTAL_TIMEOUT="${REPORT_TOTAL_TIMEOUT:-600}"
CONNECT_TIMEOUT="${REPORT_CONNECT_TIMEOUT:-60}"
CONNECT_RETRIES="${REPORT_CONNECT_RETRIES:-2}"
CONNECT_RETRY_DELAY="${REPORT_CONNECT_RETRY_DELAY:-2}"
LOCALHOST=0

usage() { awk 'NR > 1 && !/^#/ { exit } NR > 1' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--scripts-dir) SCRIPTS_DIR=$2; shift 2 ;;
    -m|--normalize-script) NORMALIZE_SCRIPT=$2; shift 2 ;;
    -o|--out-dir) OUT_BASE=$2; shift 2 ;;
    -k|--kinds) KINDS=$2; shift 2 ;;
    -c|--config) CONFIG_FILE=$2; CONFIG_FILE_IS_DEFAULT=0; shift 2 ;;
    -n|--default-dbname) DEFAULT_DBNAME=$2; shift 2 ;;
    -f|--format) FORMAT=$2; shift 2 ;;
    -t|--stmt-timeout) STMT_TIMEOUT=$2; shift 2 ;;
    -T|--total-timeout) TOTAL_TIMEOUT=$2; shift 2 ;;
    -C|--connect-timeout) CONNECT_TIMEOUT=$2; shift 2 ;;
    -r|--connect-retries) CONNECT_RETRIES=$2; shift 2 ;;
    --connect-retry-delay) CONNECT_RETRY_DELAY=$2; shift 2 ;;
    --localhost) LOCALHOST=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
done

case "$FORMAT" in
  md)      EXT=md;  NORMALIZE_ARGS=(--tables md) ;;
  md-code) EXT=md;  NORMALIZE_ARGS=(--tables code) ;;
  raw)     EXT=txt; NORMALIZE_ARGS=() ;;
  *) echo "Invalid --format '$FORMAT' (expected md, md-code or raw)." >&2; exit 2 ;;
esac
for v in CONNECT_TIMEOUT CONNECT_RETRIES CONNECT_RETRY_DELAY; do
  [[ "${!v}" =~ ^[0-9]+$ ]] || { echo "Invalid $v '${!v}' (expected a whole number of seconds/attempts)." >&2; exit 2; }
  # 10#: a leading zero ("08") would otherwise be read as octal later on.
  printf -v "$v" '%d' "$((10#${!v}))"
done

declare -A LABEL=()
declare -A DBNAME=()
declare -A OVR_STMT=() OVR_TOTAL=()

if [[ "$LOCALHOST" -eq 1 ]]; then
  [[ $# -gt 0 || -n "${REPORT_SERVICES:-}" ]] && echo "WARN  --localhost ignores services given on the command line / REPORT_SERVICES" >&2
  HOSTNAME_LABEL=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo localhost)
  SERVICES=("$HOSTNAME_LABEL")
else
  # Config file: resolved and loaded before the service-list fallback below,
  # since an empty command line falls back to the services listed in it.
  if [[ -z "$CONFIG_FILE" ]]; then
    CONFIG_FILE="$SELF_DIR/report.conf"
    CONFIG_FILE_IS_DEFAULT=1
  fi
  case "$CONFIG_FILE" in /*) ;; *) CONFIG_FILE="$PWD/$CONFIG_FILE" ;; esac

  declare -A CONFIG_SEEN=()
  SERVICE_ORDER=()
  if [[ -f "$CONFIG_FILE" ]]; then
    while read -r svc label dbname stmt total kind _; do
      [[ -z "$svc" || "$svc" == \#* ]] && continue
      [[ -n "${CONFIG_SEEN[$svc]:-}" ]] || { SERVICE_ORDER+=("$svc"); CONFIG_SEEN[$svc]=1; }
      [[ -n "$label" && "$label" != "-" ]] && LABEL[$svc]=$label
      [[ -n "$dbname" && "$dbname" != "-" ]] && DBNAME[$svc]=$dbname
      [[ -z "$kind" || "$kind" == "-" ]] && kind="*"
      [[ -n "$stmt" && "$stmt" != "-" ]] && OVR_STMT["$svc:$kind"]=$stmt
      [[ -n "$total" && "$total" != "-" ]] && OVR_TOTAL["$svc:$kind"]=$total
    done < "$CONFIG_FILE"
  elif [[ "$CONFIG_FILE_IS_DEFAULT" -eq 0 ]]; then
    echo "Config file not found: $CONFIG_FILE" >&2; exit 2
  fi

  SERVICES=("$@")
  if [[ ${#SERVICES[@]} -eq 0 && -n "${REPORT_SERVICES:-}" ]]; then
    IFS=', ' read -r -a SERVICES <<<"${REPORT_SERVICES}"
  fi
  if [[ ${#SERVICES[@]} -eq 0 && ${#SERVICE_ORDER[@]} -gt 0 ]]; then
    SERVICES=("${SERVICE_ORDER[@]}")
    echo "No service given on the command line — using the ${#SERVICES[@]} service(s) listed in $CONFIG_FILE" >&2
  fi
  if [[ ${#SERVICES[@]} -eq 0 ]]; then
    echo "No service given. Pass one or more pg_service.conf service names as arguments, set REPORT_SERVICES, or list them in the config file (-c/--config, default $SELF_DIR/report.conf), or use --localhost." >&2
    usage >&2
    exit 2
  fi
fi

IFS=',' read -r -a KIND_LIST <<<"$KINDS"
[[ ${#KIND_LIST[@]} -eq 0 ]] && { echo "No report kind given via --kinds/REPORT_KINDS." >&2; exit 2; }

# Resolve to absolute paths now — we cd into SELF_DIR further down, and
# after that any relative --out-dir/--scripts-dir/--normalize-script would
# resolve wrongly.
case "$SCRIPTS_DIR" in /*) ;; *) SCRIPTS_DIR="$PWD/$SCRIPTS_DIR" ;; esac
case "$OUT_BASE" in /*) ;; *) OUT_BASE="$PWD/$OUT_BASE" ;; esac
case "$NORMALIZE_SCRIPT" in /*) ;; *) NORMALIZE_SCRIPT="$PWD/$NORMALIZE_SCRIPT" ;; esac

[[ -d "$SCRIPTS_DIR" ]] || { echo "--scripts-dir '$SCRIPTS_DIR' is not a directory. Point -d/--scripts-dir (or REPORT_SCRIPTS_DIR) at the sql/ fragment library." >&2; exit 2; }

if [[ ! -f "$SELF_DIR/report_cluster.sql" && " ${KIND_LIST[*]} " == *" cluster "* ]] \
   || [[ ! -f "$SELF_DIR/report_database.sql" && " ${KIND_LIST[*]} " == *" database "* ]]; then
  echo "report_*.sql not found next to this script ($SELF_DIR). generate_reports.sh must stay alongside report_cluster.sql/report_database.sql." >&2
  exit 2
fi

[[ -d "$NORMALIZE_SCRIPT" ]] && NORMALIZE_SCRIPT="$NORMALIZE_SCRIPT/normalize_md.py"
if [[ "$FORMAT" != raw && ! -f "$NORMALIZE_SCRIPT" ]]; then
  echo "normalize_md.py not found at '$NORMALIZE_SCRIPT'. Point -m/--normalize-script (or REPORT_NORMALIZE_SCRIPT) at it." >&2
  exit 2
fi

# Locate pg_service.conf the same way libpq does (PGSERVICEFILE >
# PGSYSCONFDIR > `pg_config --sysconfdir` > ~/.pg_service.conf), purely to
# give a clearer pre-flight warning than psql's own connection error when a
# requested service is missing. Non-fatal either way — psql does its own
# resolution (and may find a service file this check doesn't) when it
# actually connects.
resolve_pg_service_file() {
  if [[ -n "${PGSERVICEFILE:-}" && -f "$PGSERVICEFILE" ]]; then
    printf '%s\n' "$PGSERVICEFILE"; return 0
  fi
  if [[ -n "${PGSYSCONFDIR:-}" && -f "$PGSYSCONFDIR/pg_service.conf" ]]; then
    printf '%s\n' "$PGSYSCONFDIR/pg_service.conf"; return 0
  fi
  if command -v pg_config >/dev/null 2>&1; then
    local sysconfdir
    sysconfdir=$(pg_config --sysconfdir 2>/dev/null) || sysconfdir=""
    if [[ -n "$sysconfdir" && -f "$sysconfdir/pg_service.conf" ]]; then
      printf '%s\n' "$sysconfdir/pg_service.conf"; return 0
    fi
  fi
  if [[ -f "$HOME/.pg_service.conf" ]]; then
    printf '%s\n' "$HOME/.pg_service.conf"; return 0
  fi
  return 1
}

# Auto-detects a database for "database" kind reports when neither the
# config file nor --default-dbname picked one for this service (lowest
# priority, see the header comment): connects (using the same conn string
# the caller is about to use, minus any dbname) to whatever database that
# resolves to by default, and prefers the busiest database by
# pg_stat_statements load, if that view is usable there, otherwise the
# largest by size. Prints the resolved dbname on stdout, or nothing on
# failure/empty cluster.
#
# Two steps on purpose: a single CASE WHEN EXISTS (...) query fails at
# parse time when pg_stat_statements isn't installed (the relation is
# resolved even in the branch that never runs), so the size fallback never
# ran. The pg_stat_statements query also runs when the extension exists but
# isn't in shared_preload_libraries (the view then errors out), so an empty
# result falls back to size as well. total_exec_time/total_plan_time only
# exist from pg_stat_statements 1.8 (PG 13); older versions use total_time.
# The probe uses pg_class + pg_table_is_visible() rather than to_regclass()
# (PG 9.4+) so it works on every server version the SQL scripts support; if
# it fails anyway, the size query still runs.
resolve_auto_dbname() {
  local conn_base="$1" probe load dbname
  probe=$(timeout 30 psql "$conn_base" -X -q -t -A -F ' ' -c "
    SELECT EXISTS (SELECT 1 FROM pg_class c
                   WHERE c.relname = 'pg_stat_statements' AND pg_table_is_visible(c.oid)),
           EXISTS (SELECT 1 FROM pg_class c
                   JOIN pg_attribute a ON a.attrelid = c.oid
                   WHERE c.relname = 'pg_stat_statements' AND pg_table_is_visible(c.oid)
                     AND a.attname = 'total_exec_time');
  " 2>/dev/null) || probe=""

  if [[ "$probe" == "t "* ]]; then
    if [[ "$probe" == "t t" ]]; then
      load="sum(s.total_plan_time) + sum(s.total_exec_time)"
    else
      load="sum(s.total_time)"
    fi
    dbname=$(timeout 30 psql "$conn_base" -X -q -t -A -c "
      SELECT d.datname
      FROM pg_stat_statements s
      JOIN pg_database d ON d.oid = s.dbid
      WHERE d.datistemplate IS FALSE
      GROUP BY d.datname
      ORDER BY $load DESC
      LIMIT 1;
    " 2>/dev/null)
    [[ -n "$dbname" ]] && { printf '%s\n' "$dbname"; return 0; }
  fi

  timeout 30 psql "$conn_base" -X -q -t -A -c "
    SELECT datname FROM pg_database
    WHERE datistemplate IS FALSE
    ORDER BY pg_database_size(datname) DESC
    LIMIT 1;
  " 2>/dev/null
}

if [[ "$LOCALHOST" -ne 1 ]]; then
  if PG_SERVICE_FILE=$(resolve_pg_service_file); then
    for svc in "${SERVICES[@]}"; do
      grep -qE "^\[$svc\]" "$PG_SERVICE_FILE" 2>/dev/null \
        || echo "WARN  service '$svc' not found in $PG_SERVICE_FILE — will still try, psql may resolve it differently" >&2
    done
  else
    echo "WARN  no pg_service.conf found (checked \$PGSERVICEFILE, \$PGSYSCONFDIR, 'pg_config --sysconfdir', \$HOME/.pg_service.conf) — services will be validated by psql itself" >&2
  fi
fi

cd "$SELF_DIR" || exit 2

DATE=$(date +%F)
OUT="$OUT_BASE/$DATE"
mkdir -p "$OUT"

declare -A AUTO_DBNAME_CACHE=()

# Last stage of the report pipeline: Markdown conversion, or a plain
# passthrough with --format raw.
normalize() {
  if [[ "$FORMAT" == raw ]]; then
    cat
  else
    python3 "$NORMALIZE_SCRIPT" "${NORMALIZE_ARGS[@]}"
  fi
}

# Opens one throwaway connection ("SELECT 1"), retrying up to
# CONNECT_RETRIES more times when psql can't connect (exit code 2) — e.g.
# a link that drops a connection now and then. Any other outcome is left
# for the report itself. Prints a RETRY line per retry; on final failure,
# leaves the last error in the given file and returns 1.
wait_for_connection() {
  local conn=$1 label=$2 errfile=$3 attempt rc
  for (( attempt = 1; attempt <= CONNECT_RETRIES + 1; attempt++ )); do
    psql "$conn" -X -q -At -c 'SELECT 1' >/dev/null 2>"$errfile"
    rc=$?
    (( rc != 2 )) && { rm -f "$errfile"; return 0; }
    (( attempt > CONNECT_RETRIES )) && return 1
    echo "RETRY $label (attempt $((attempt + 1))/$((CONNECT_RETRIES + 1)) in ${CONNECT_RETRY_DELAY}s: $(head -1 "$errfile"))"
    sleep "$CONNECT_RETRY_DELAY"
  done
}

fail=0
for svc in "${SERVICES[@]}"; do
  label=${LABEL[$svc]:-$svc}
  for kind in "${KIND_LIST[@]}"; do
    # Wildcard ("*" kind) override applies first, then the exact-kind
    # override on top of it — stmt and total are resolved independently,
    # so a config line can override just one of the two.
    stmt="$STMT_TIMEOUT"; total="$TOTAL_TIMEOUT"
    [[ -n "${OVR_STMT[$svc:*]:-}" ]] && stmt=${OVR_STMT[$svc:*]}
    [[ -n "${OVR_STMT[$svc:$kind]:-}" ]] && stmt=${OVR_STMT[$svc:$kind]}
    [[ -n "${OVR_TOTAL[$svc:*]:-}" ]] && total=${OVR_TOTAL[$svc:*]}
    [[ -n "${OVR_TOTAL[$svc:$kind]:-}" ]] && total=${OVR_TOTAL[$svc:$kind]}

    f="$OUT/${DATE}_${label}_${kind}.${EXT}"
    if [[ "$LOCALHOST" -eq 1 ]]; then
      conn="connect_timeout=$CONNECT_TIMEOUT"
    else
      conn="service=$svc connect_timeout=$CONNECT_TIMEOUT"
    fi
    if ! wait_for_connection "$conn" "$svc $kind" "$f.err"; then
      echo "FAIL  $svc $kind (could not connect after $((CONNECT_RETRIES + 1)) attempt(s): $(head -1 "$f.err" 2>/dev/null))"
      fail=1
      continue
    fi
    if [[ "$kind" == database ]]; then
      dbname="${DBNAME[$svc]:-}"
      [[ -z "$dbname" ]] && dbname="$DEFAULT_DBNAME"
      if [[ -z "$dbname" ]]; then
        if [[ -z "${AUTO_DBNAME_CACHE[$svc]+set}" ]]; then
          AUTO_DBNAME_CACHE[$svc]=$(resolve_auto_dbname "$conn")
        fi
        dbname="${AUTO_DBNAME_CACHE[$svc]}"
        [[ -z "$dbname" ]] && echo "WARN  could not auto-detect a database for $svc — falling back to this connection's own default database" >&2
      fi
      [[ -n "$dbname" ]] && conn="$conn dbname=$dbname"
    fi

    if [[ ! -f "report_${kind}.sql" ]]; then
      echo "SKIP  $svc $kind (report_${kind}.sql not found in $SELF_DIR)"
      fail=1
      continue
    fi

    # Report includes do \set QUIET off, so psql echoes \timing/\pset
    # feedback to stdout. stdbuf -oL forces the \o pipe's sed to be
    # line-buffered (inherited via env), so that feedback comes out as
    # whole lines — removed by the grep below.
    if timeout "$total" stdbuf -oL psql "$conn" -X -q -v sql_dir="$SCRIPTS_DIR" \
        -c "SET statement_timeout='${stmt}'; SET lock_timeout='3s';" \
        -f "report_${kind}.sql" 2>"$f.err" \
        | grep -vE '^(Timing is|Expanded display is|Null display is|Border style is|Pager usage is|Output format is|Tuples only is|Footer is|Title is)' \
        | normalize > "$f"; then
      if [[ -s "$f" ]]; then
        echo "OK    $svc $kind -> $f"
        rm -f "$f.err"
      else
        echo "EMPTY $svc $kind ($(head -1 "$f.err" 2>/dev/null))"
        rm -f "$f"
        fail=1
      fi
    else
      echo "FAIL  $svc $kind ($(head -1 "$f.err" 2>/dev/null))"
      rm -f "$f"
      fail=1
    fi
  done
done
exit $fail

