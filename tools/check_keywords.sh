#!/usr/bin/env bash
#
# Checks that reserved SQL keywords are uppercase in sql/*.sql and
# reports/*.sql, as CONTRIBUTING.md and CLAUDE.md require.
#
# "Reserved" means PostgreSQL's own list: pg_get_keywords() categories R
# (reserved) and T (reserved, can be a function or type name), taken from
# PostgreSQL 15, plus SYSTEM_USER (reserved since 16). Not checked, because
# case doesn't matter there or the word isn't a keyword:
#   - strings ('...', E'...'), $$...$$ / $tag$...$tag$ literals,
#     "quoted" identifiers, -- and /* */ comments, psql \meta-command lines
#   - words right after '.', AS or ':' (column labels, psql variables)
#   - T keywords used as function calls, e.g. left(...), right(...)
#   - functions such as now() or current_schema(), which are lowercase
#
# Requirements: bash and python3 (standard library only).
#
# Usage:
#   ./tools/check_keywords.sh [--fix] [repo_dir]
#   (repo_dir defaults to the parent directory of this script)
#   --fix  rewrites the files in place, uppercasing only the reported words
#
# Exit code: 0 when everything is fine (or --fix fixed everything), 1 when
# any lowercase keyword is found. Problems are printed as "file:line: message".
#
# To run it before every commit, together with the dispatcher check:
#   printf '#!/bin/sh\n./tools/check_dispatchers.sh && ./tools/check_keywords.sh\n' > .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit

set -euo pipefail

fix=0
if [ "${1:-}" = "--fix" ]; then fix=1; shift; fi

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

FIX="$fix" python3 - sql/*.sql reports/*.sql <<'PY'
import os, re, sys

RESERVED = """all analyse analyze and any array as asc asymmetric both case cast check
collate column constraint create current_catalog current_date current_role
current_time current_timestamp current_user default deferrable desc distinct do
else end except false fetch for foreign from grant group having in initially
intersect into lateral leading limit localtime localtimestamp not null offset on
only or order placing primary references returning select session_user some
symmetric system_user table then to trailing true union unique user using
variadic when where window with""".split()
FUNC_OR_TYPE = """authorization binary collation concurrently cross current_schema
freeze full ilike inner is isnull join left like natural notnull outer overlaps
right similar tablesample verbose""".split()
KW = {w: "R" for w in RESERVED} | {w: "T" for w in FUNC_OR_TYPE}

PROTECTED = (r"--[^\n]*|/\*.*?\*/|\$([A-Za-z_]*)\$.*?\$\1\$"
             r"|[Ee]'(?:\\.|''|[^'])*'|'(?:''|[^'])*'|\"[^\"]*\"|^[ \t]*\\[^\n]*")
TOKEN = re.compile(PROTECTED + r"|[A-Za-z_][A-Za-z0-9_$]*|\S", re.S | re.M)

def is_protected(t):
    return (t[:2] in ("--", "/*", "E'", "e'") or t[0] in "$'\""
            or t.lstrip().startswith("\\"))

def lowercase_keywords(src):
    """Yield (match, word) for every reserved keyword that isn't uppercase."""
    prev = ""
    for m in TOKEN.finditer(src):
        t = m.group(0)
        if is_protected(t):
            prev = ""
            continue
        lw = t.lower()
        if lw in KW and t != t.upper() and prev not in (".", "as", ":"):
            if not (KW[lw] == "T" and src[m.end():].lstrip()[:1] == "("):
                yield m, t
        prev = lw

fix = os.environ.get("FIX") == "1"
found = fixed = 0
for path in sys.argv[1:]:
    with open(path, newline="") as f:
        src = f.read()
    hits = list(lowercase_keywords(src))
    if not hits:
        continue
    if fix:
        out, last = [], 0
        for m, t in hits:
            out += [src[last:m.start()], t.upper()]
            last = m.end()
        out.append(src[last:])
        new = "".join(out)
        assert new.lower() == src.lower(), f"{path}: non case-only change"
        with open(path, "w", newline="") as f:
            f.write(new)
        fixed += len(hits)
        print(f"{path}: uppercased {len(hits)} keyword(s)")
    else:
        for m, t in hits:
            line = src.count("\n", 0, m.start()) + 1
            print(f"{path}:{line}: keyword '{t}' should be uppercase ({t.upper()})")
        found += len(hits)

if fix:
    print(f"\nFixed {fixed} keyword(s)" if fixed else "All keywords OK")
    sys.exit(0)
if found:
    print(f"\n{found} problem(s) found (run ./tools/check_keywords.sh --fix to fix them)")
    sys.exit(1)
print("All keywords OK")
PY
