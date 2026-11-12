#!/usr/bin/env bash
# Test battery for one PostgreSQL server: runs every entry script in sql/
# (dispatchers and unversioned files, not the _VVup/_VV- implementations) and
# both reports (reports/generate_reports.sh), and records for each one the exit
# code, output lines and ERROR / FATAL / timeout counts. tools/check_battery.py
# then compares the results with tools/known_failures.csv.
#
# Requirements: bash 4+, psql 12+ in PATH (the scripts need 10+ for \if; the
# battery needs 12+, whose client errors start with "error:"; any server
# 8.2 -> 18), GNU timeout (`timeout` or Homebrew's `gtimeout`), a superuser
# connection through the usual libpq variables (PGHOST, PGPORT, PGUSER,
# PGSERVICE...). The report SQL files run directly (rows report_cluster and
# report_database, stderr included); generate_reports.sh runs too (row REPORTS)
# when there is a pg_service.conf entry (-S or PGSERVICE).
#
# Important: for THROWAWAY test clusters only. The battery runs everything,
# including kill_* (terminates sessions), stats_reset_all (resets statistics),
# pgbouncer_fdw (creates a schema) and the \gexec scripts, which really act on
# the server.
#
# Usage: tools/run_battery.sh [options]
#   -o, --out DIR        output directory (default: battery_out/<version>)
#   -d, --dbname DB      database to run the scripts on (default: the fixture's
#                        database with --fixture, else PGDATABASE or postgres)
#   -f, --fixture        rebuild and load tools/fixture.sh first and keep its
#                        background sessions running during the battery; the
#                        rebuild makes every run start from the same state (the
#                        battery changes it: pgbouncer_fdw, stats_reset_all...)
#       --reuse-fixture  with --fixture: keep the database when it is already at
#                        the fixture's version (faster, e.g. to iterate on one
#                        script), only load it again
#   -s, --scripts LIST   only these entry scripts (names without .sql, space
#                        separated)
#   -S, --service NAME   pg_service.conf entry for the reports (default PGSERVICE)
#   -R, --no-reports     skip the reports
#   -t, --timeout SECS   per-script timeout (default 120)
#   -h, --help
# Output: DIR/results.csv (version,script,rc,lines,errors,fatal,timeout,
#         not_supported,needs,md5), DIR/<script>.out, DIR/report_<kind>.out,
#         DIR/reports/ + reports.log (generate_reports.sh), DIR/fixture.log
# Example: PGSERVICE=pg16 tools/run_battery.sh --fixture -o /tmp/battery/16
#          tools/check_battery.py /tmp/battery
set -euo pipefail

usage() { sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'; }
REPO=$(cd "$(dirname "$0")/.." && pwd)
OUT=""; DB=""; FIXTURE=""; REUSE=""; ONLY=""; SERVICE="${PGSERVICE:-}"; NO_REPORTS=""; TMO=120
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out) OUT=$2; shift 2 ;;
    -d|--dbname) DB=$2; shift 2 ;;
    -f|--fixture) FIXTURE=1; shift ;;
    --reuse-fixture) REUSE=1; shift ;;
    -s|--scripts) ONLY=$2; shift 2 ;;
    -S|--service) SERVICE=$2; shift 2 ;;
    -R|--no-reports) NO_REPORTS=1; shift ;;
    -t|--timeout) TMO=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
done

die() { echo "run_battery: $*" >&2; exit 2; }
# ERROR/FATAL are counted by their English text: no translated messages,
# neither from psql nor from the server
export LC_ALL=C PGOPTIONS="${PGOPTIONS:+$PGOPTIONS }-c lc_messages=C"
if command -v timeout >/dev/null && timeout --version >/dev/null 2>&1; then TIMEOUT=timeout
elif command -v gtimeout >/dev/null; then TIMEOUT=gtimeout
else die "needs GNU timeout (Linux coreutils, or 'brew install coreutils' for gtimeout)"; fi
if command -v md5sum >/dev/null; then md5f() { md5sum < "$1" | cut -d' ' -f1; }; else md5f() { md5 -q "$1"; }; fi
command -v psql >/dev/null || die "needs psql in PATH"
# psql 12+: before it, client errors (e.g. an \ir to a missing file) have no
# "error:" prefix, and the battery could not tell them from normal output
[[ $(psql --version | sed -E 's/^[^0-9]*([0-9]+).*/\1/') -ge 12 ]] || die "needs psql 12+ in PATH (client errors are only recognizable from 12 on)"
if [[ -n "$FIXTURE" ]]; then DB=${DB:-${FIXDB:-fixdb}}; export FIXDB=$DB; else DB=${DB:-${PGDATABASE:-postgres}}; fi
svn=$(psql -X -At -d postgres -c 'SHOW server_version_num' </dev/null 2>/dev/null) || die "cannot connect (set PGHOST/PGPORT/PGUSER or PGSERVICE)"
if [[ $svn -ge 100000 ]]; then v=$(( svn / 10000 )); else v=$(( svn / 10000 * 10 + svn / 100 % 100 )); fi
OUT=${OUT:-battery_out/$v}; mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)

if [[ -n "$ONLY" ]]; then SCRIPTS=$(for s in $ONLY; do echo "$s.sql"; done)
else SCRIPTS=$(cd "$REPO/sql" && ls *.sql | grep -vE '_[0-9]{2}(up|-)\.sql$'); fi
# statistics resets last: in name order stats_reset_all would zero the
# counters that tables_delete/_insert/_update and others read after it
SCRIPTS=$(printf '%s\n' $SCRIPTS | grep -v '^stats_reset' || true; printf '%s\n' $SCRIPTS | grep '^stats_reset' || true)

fix() { "$REPO/tools/fixture.sh" "$@" >> "$OUT/fixture.log" 2>&1; }
CSV="$OUT/results.csv"
echo "version,script,rc,lines,errors,fatal,timeout,not_supported,needs,md5" > "$CSV"
# the last row: check_battery.py treats a results.csv without it as an
# interrupted run, not a clean one
end_row() { echo "$v,END,0,0,0,0,0,0,0," >> "$CSV"; }
fixture_failed() {
  echo "$v,FIXTURE,1,0,1,0,0,0,0," >> "$CSV"
  echo "pg$v: fixture failed, nothing run (see $OUT/fixture.log)" >&2
  end_row
  exit 1
}
if [[ -n "$FIXTURE" ]]; then
  : > "$OUT/fixture.log"
  # a database the fixture refused (or failed to build) is neither tested nor
  # cleaned up: the stop trap only once the build succeeded
  if [[ -n "$REUSE" ]]; then fix || fixture_failed; else fix --rebuild || fixture_failed; fi
  trap 'fix stop || true' EXIT
  trap 'exit 130' INT TERM  # a killed battery still stops the fixture sessions (EXIT trap)
  fix start || fixture_failed
fi

cnt() { grep -cE "$1" "$2" || true; }
# server errors, plus psql's own (e.g. an \ir to a missing file), which it
# prints as "psql:<file>:<line>: error: ..." and then exits with 0
ERR='ERROR:|^psql:[^ ]+: error:'
for s in $SCRIPTS; do
  o="$OUT/${s%.sql}.out"; rc=0
  (cd "$REPO/sql" && "$TIMEOUT" "$TMO" psql -X -d "$DB" -f "$s" </dev/null > "$o" 2>&1) || rc=$?
  to=0; [[ $rc -eq 124 ]] && to=1
  echo "$v,${s%.sql},$rc,$(wc -l < "$o" | tr -d ' '),$(cnt "$ERR" "$o"),$(cnt 'FATAL:' "$o"),$to,$(cnt 'Not supported on version' "$o"),$(cnt '^- Needs' "$o"),$(md5f "$o")" >> "$CSV"
done

if [[ -z "$NO_REPORTS" && -z "$ONLY" ]]; then
  # stats_reset_all emptied pg_stat_statements: load it again for the reports
  if [[ -n "$FIXTURE" ]] && ! fix load; then
    echo "$v,FIXTURE_LOAD,1,0,1,0,0,0,0," >> "$CSV"  # the reports would run without the workload
  fi
  # the report SQL on its own, stderr included: generate_reports.sh keeps psql's
  # stderr only when a report fails, so an error inside a report section that
  # still produces output would not show up in the Markdown
  for k in cluster database; do
    o="$OUT/report_$k.out"; rc=0
    (cd "$REPO/reports" && "$TIMEOUT" 1200 psql -X -d "$DB" -v sql_dir="$REPO/sql" -f "report_$k.sql" </dev/null > "$o" 2>&1) || rc=$?
    to=0; [[ $rc -eq 124 ]] && to=1
    echo "$v,report_$k,$rc,$(wc -l < "$o" | tr -d ' '),$(cnt "$ERR" "$o"),$(cnt 'FATAL:' "$o"),$to,0,0,$(md5f "$o")" >> "$CSV"
  done
  if [[ -z "$SERVICE" ]]; then
    echo "pg$v: reports skipped (no -S/PGSERVICE)" >&2
  else
    rrc=0
    # an explicit, empty config: reports/report.conf (git-ignored, local) would
    # otherwise be read by default and its dbname would win over -n
    echo "# empty: no per-service overrides for the battery" > "$OUT/report.conf.battery"
    # a reused output directory: count only this run's reports. Only the date
    # folders generate_reports.sh creates go, never the directory itself (with
    # -o at the repository root, $OUT/reports is the repository's reports/)
    if [[ -d "$OUT/reports" ]]; then
      find "$OUT/reports" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' -exec rm -rf {} +
    fi
    (cd "$REPO/reports" && "$TIMEOUT" 1200 ./generate_reports.sh -k cluster,database -f md -n "$DB" \
        -c "$OUT/report.conf.battery" -o "$OUT/reports" "$SERVICE") \
      </dev/null > "$OUT/reports.log" 2>&1 || rrc=$?
    md=$(cat "$OUT"/reports/*/*.md 2>/dev/null || true)
    echo "$v,REPORTS,$rrc,$(printf '%s' "$md" | grep -c '' || true),$(printf '%s' "$md" | grep -c 'ERROR:' || true),$(cnt 'FATAL:' "$OUT/reports.log"),0,0,0,$(ls "$OUT"/reports/*/*.md 2>/dev/null | wc -l | tr -d ' ')" >> "$CSV"
  fi
fi
end_row
bad=$(awk -F, 'NR > 1 && ($5 > 0 || $6 > 0 || $7 > 0 || ($2 == "REPORTS" && $3 != 0))' "$CSV" | wc -l | tr -d ' ')
echo "pg$v: $(( $(wc -l < "$CSV") - 2 )) runs, $bad with ERROR/FATAL/timeout -> $CSV"
