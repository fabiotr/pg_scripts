#!/usr/bin/env bash
#
# Checks the SQL dispatcher conventions described in CLAUDE.md.
#
# For every sql/*.sql file (and reports/*.sql for includes only):
#   - \i is not used in sql/ (use \ir, which resolves relative to the file)
#   - every \i / \ir target exists
#   - a branch `\if :svp_pg_VV` / `\elif :svp_pg_VV` includes <name>_VVup.sql
#     (the version in the condition matches the version in the file name)
#   - the svp_pg_* branches of an \if chain go from newest to oldest version
#   - every versioned file (<name>_VVup.sql, <name>_VV-.sql) is included by
#     some script, i.e. no unreachable implementation
#   - the fallback message is "\qecho - Not supported on version ..." (capital N)
#
# Requirements: bash, git (only to find the repo when run as a hook) and a
# POSIX awk (tested with the BSD awk shipped with macOS).
#
# Usage:
#   ./tools/check_dispatchers.sh [repo_dir]
#   (repo_dir defaults to the parent directory of this script)
#
# Exit code: 0 when everything is fine, 1 when any problem is found.
# Problems are printed as "file:line: message".
#
# To run it before every commit:
#   ln -s ../../tools/check_dispatchers.sh .git/hooks/pre-commit

set -euo pipefail

# Default: the parent of this script's directory, or the git top level when
# run through a symlink (e.g. .git/hooks/pre-commit)
repo_dir="${1:-}"
if [ -z "$repo_dir" ]; then
    repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [ ! -f "$repo_dir/sql/variables.sql" ]; then
        repo_dir="$(git rev-parse --show-toplevel 2>/dev/null || echo "$repo_dir")"
    fi
fi
cd "$repo_dir"

if [ ! -f sql/variables.sql ]; then
    echo "error: $repo_dir doesn't look like the pg_scripts repository (sql/variables.sql not found)" >&2
    exit 2
fi

# First input: the list of existing files (one "dir/file" per line), then the scripts themselves
file_list="$(mktemp)"
trap 'rm -f "$file_list"' EXIT
# nullglob: a missing reports/*.sql expands to nothing, not to the literal pattern
shopt -s nullglob
scripts=(sql/*.sql reports/*.sql)
printf '%s\n' "${scripts[@]}" > "$file_list"

awk '
# Converts a svp_pg_* / file name version suffix to a comparable number: 82 -> 8.2, 96 -> 9.6, 10 -> 10
function version_num(v) { return (v + 0 >= 80) ? v / 10 : v + 0 }

function problem(msg) { printf "%s:%d: %s\n", FILENAME, FNR, msg; errors++ }

# Returns the NN of ":svp_pg_NN" in the condition of an \if / \elif line, or "" for any other condition
function pg_condition(line) {
    if (match(line, /:svp_pg_[0-9]+[[:space:]]*$/)) {
        v = substr(line, RSTART + 8, RLENGTH - 8)
        sub(/[[:space:]]+$/, "", v)
        return v
    }
    return ""
}

NR == FNR { exists[$0] = 1; next }

FNR == 1 {
    depth = 0
    dir = FILENAME; sub(/\/[^\/]*$/, "", dir)
    in_sql = (dir ~ /(^|\/)sql$/)
}

# Skip comment lines
/^[[:space:]]*--/ { next }

/^[[:space:]]*\\if[[:space:]]/ {
    depth++
    cond[depth] = pg_condition($0)
    last[depth] = cond[depth]
    next
}

/^[[:space:]]*\\elif[[:space:]]/ {
    cond[depth] = pg_condition($0)
    if (cond[depth] != "" && last[depth] != "" && version_num(cond[depth]) >= version_num(last[depth]))
        problem("branch svp_pg_" cond[depth] " comes after svp_pg_" last[depth] " (branches must go from newest to oldest)")
    if (cond[depth] != "") last[depth] = cond[depth]
    next
}

/^[[:space:]]*\\else([[:space:]]|$)/ { cond[depth] = ""; next }

/^[[:space:]]*\\endif([[:space:]]|$)/ { if (depth > 0) depth--; next }

/^[[:space:]]*\\ir?[[:space:]]/ {
    line = $0
    sub(/^[[:space:]]*\\/, "", line)
    cmd = line; sub(/[[:space:]].*$/, "", cmd)
    target = line; sub(/^[a-z]+[[:space:]]+/, "", target); sub(/[[:space:]].*$/, "", target)

    if (cmd == "i" && in_sql)
        problem("uses \\i " target " (use \\ir, \\i only works when the current directory is sql/)")

    # Targets built from psql variables (e.g. :sql_dir) cannot be checked
    if (target ~ /:/) next

    name = target; sub(/^.*\//, "", name)
    included[name] = 1

    if (!(("sql/" name) in exists) && !((dir "/" target) in exists))
        problem("includes " target ", which does not exist")

    if (match(name, /_[0-9]+up\.sql$/) && depth > 0 && cond[depth] != "") {
        file_version = substr(name, RSTART + 1, RLENGTH - 7)
        if (file_version != cond[depth])
            problem("branch svp_pg_" cond[depth] " includes " name " (version mismatch)")
    }
    next
}

/\\qecho - not supported on version/ {
    problem("use \"\\qecho - Not supported on version :svp_server_version\" (capital N)")
}

END {
    for (f in exists) {
        name = f; sub(/^.*\//, "", name)
        if (f ~ /^sql\// && name ~ /_[0-9]+(up|-)\.sql$/ && !(name in included)) {
            printf "%s: is not included by any script (unreachable)\n", f
            errors++
        }
    }
    if (errors) {
        printf "\n%d problem(s) found\n", errors
        exit 1
    }
    print "All dispatchers OK"
}
' "$file_list" "${scripts[@]}"
