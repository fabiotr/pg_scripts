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
#     "quoted" identifiers, -- and /* */ comments (nested ones too),
#     psql \meta-command lines
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

# Literal text that is never checked. $tag$ follows the identifier rule
# (letter or _, then letters, digits or _); an empty tag is $$.
LITERAL = re.compile(
    r"--[^\n]*"                                   # line comment
    r"|\$((?:[A-Za-z_][A-Za-z0-9_]*)?)\$.*?\$\1\$"  # $$...$$ / $tag$...$tag$
    r"|[Ee]'(?:\\.|''|[^'])*'"                    # E'...' string
    r"|'(?:''|[^'])*'"                            # '...' string
    r"|\"[^\"]*\"",                               # "quoted" identifier
    re.S)
WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_$]*")
SPACE = re.compile(r"\s+")

def block_comment_end(src, pos):
    """End of the /* ... */ comment starting at pos. PostgreSQL block
    comments nest, so count the depth instead of stopping at the first */."""
    depth, i = 0, pos
    while i < len(src):
        if src.startswith("/*", i):
            depth += 1; i += 2
        elif src.startswith("*/", i):
            depth -= 1; i += 2
            if depth == 0:
                return i
        else:
            i += 1
    return len(src)                               # unterminated: rest of file

def tokens(src):
    """Yield (start, end, text, is_literal) for every non-space token."""
    pos = 0
    while pos < len(src):
        m = SPACE.match(src, pos)
        if m:
            pos = m.end(); continue
        line_start = src.rfind("\n", 0, pos) + 1
        if src[pos] == "\\" and src[line_start:pos].strip() == "":
            end = src.find("\n", pos)             # psql \meta-command line
            end = len(src) if end < 0 else end
            yield pos, end, src[pos:end], True; pos = end; continue
        if src.startswith("/*", pos):
            end = block_comment_end(src, pos)
            yield pos, end, src[pos:end], True; pos = end; continue
        m = LITERAL.match(src, pos) or WORD.match(src, pos)
        if m:
            yield pos, m.end(), m.group(0), m.re is LITERAL; pos = m.end(); continue
        yield pos, pos + 1, src[pos], False; pos += 1

def lowercase_keywords(src):
    """Yield (start, end, word) for every reserved keyword that isn't uppercase."""
    prev = ""
    for start, end, t, literal in tokens(src):
        if literal:
            prev = ""
            continue
        lw = t.lower()
        if lw in KW and t != t.upper() and prev not in (".", "as", ":"):
            if not (KW[lw] == "T" and src[end:].lstrip()[:1] == "("):
                yield start, end, t
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
        for start, end, t in hits:
            out += [src[last:start], t.upper()]
            last = end
        out.append(src[last:])
        new = "".join(out)
        assert new.lower() == src.lower(), f"{path}: non case-only change"
        with open(path, "w", newline="") as f:
            f.write(new)
        fixed += len(hits)
        print(f"{path}: uppercased {len(hits)} keyword(s)")
    else:
        for start, end, t in hits:
            line = src.count("\n", 0, start) + 1
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
