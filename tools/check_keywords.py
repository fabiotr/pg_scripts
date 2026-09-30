#!/usr/bin/env python3
"""Check that reserved SQL keywords are uppercase in sql/*.sql and
reports/*.sql, as CONTRIBUTING.md and CLAUDE.md require.

"Reserved" means PostgreSQL's own list: pg_get_keywords() categories R
(reserved) and T (reserved, can be a function or type name), taken from
PostgreSQL 15, plus SYSTEM_USER (reserved since 16). Not checked, because
case doesn't matter there or the word isn't a keyword:
  - strings ('...', E'...'), $$...$$ / $tag$...$tag$ literals, "quoted"
    identifiers, -- and /* */ comments (nested ones too), psql
    \\meta-command lines
  - words right after '.', AS or ':' (column labels, psql variables),
    also when a comment sits in between
  - T keywords used as function calls, e.g. left(...) or
    left /* ... */ (...)
  - functions such as now() or current_schema(), which are lowercase

A plain '...' string with a backslash right before its closing quote
('a\\' or 'can\\'t') is reported as ambiguous instead: where it ends
depends on standard_conforming_strings (off by default up to 9.0, on since
9.1). Nothing after it in that file is checked, since token boundaries are
unknown from there on.

Requirements: python3 (standard library only).

Usage:
  ./tools/check_keywords.py [--fix] [repo_dir]
  (repo_dir defaults to the parent directory of this script)
  --fix  rewrites the files in place, uppercasing only the reported words;
         files with an ambiguous string are left untouched

Exit code: 0 when everything is fine (or --fix fixed everything), 1 when
any problem is left. Problems are printed as "file:line: message".

To run it before every commit, together with the dispatcher check:
  printf '#!/bin/sh\\n./tools/check_dispatchers.sh && ./tools/check_keywords.py\\n' > .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
"""

import os
import re
import subprocess
import sys
from pathlib import Path

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
KEYWORDS = {w: "R" for w in RESERVED} | {w: "T" for w in FUNC_OR_TYPE}

# Token kinds
COMMENT, LITERAL, META, WORD, OTHER = "comment", "literal", "meta", "word", "other"

LITERAL_RE = re.compile(
    r"\$((?:[A-Za-z_][A-Za-z0-9_]*)?)\$.*?\$\1\$"  # $$...$$ / $tag$...$tag$ (identifier rule)
    r"|[Ee]'(?:\\.|''|[^'\\])*'"                  # E'...' string (backslash escapes; the
                                                  # classes are disjoint to avoid ReDoS)
    r"|'(?:''|[^'])*'"                            # '...' string
    r"|\"[^\"]*\"",                               # "quoted" identifier
    re.S)
WORD_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_$]*")
SPACE_RE = re.compile(r"\s+")
# A plain string whose closing quote follows an odd number of backslashes
AMBIGUOUS_END_RE = re.compile(r"(?<!\\)(?:\\\\)*\\'$")


def block_comment_end(src, pos):
    """End of the /* ... */ comment starting at pos. PostgreSQL block
    comments nest, so count the depth instead of stopping at the first */."""
    depth, i = 0, pos
    while i < len(src):
        if src.startswith("/*", i):
            depth += 1
            i += 2
        elif src.startswith("*/", i):
            depth -= 1
            i += 2
            if depth == 0:
                return i
        else:
            i += 1
    return len(src)  # unterminated: rest of the file


def tokens(src):
    """Return every non-space token as (kind, start, end, text)."""
    out, pos = [], 0
    while pos < len(src):
        m = SPACE_RE.match(src, pos)
        if m:
            pos = m.end()
            continue
        if src.startswith("--", pos):
            end = src.find("\n", pos)
            end = len(src) if end < 0 else end
            kind = COMMENT
        elif src.startswith("/*", pos):
            end, kind = block_comment_end(src, pos), COMMENT
        elif src[pos] == "\\" and src[src.rfind("\n", 0, pos) + 1:pos].strip() == "":
            end = src.find("\n", pos)  # psql \meta-command line
            end = len(src) if end < 0 else end
            kind = META
        elif (m := LITERAL_RE.match(src, pos)):
            end, kind = m.end(), LITERAL
        elif (m := WORD_RE.match(src, pos)):
            end, kind = m.end(), WORD
        else:
            end, kind = pos + 1, OTHER
        out.append((kind, pos, end, src[pos:end]))
        pos = end
    return out


def is_ambiguous_string(text):
    """True for a plain '...' literal whose end depends on
    standard_conforming_strings."""
    return text[0] == "'" and bool(AMBIGUOUS_END_RE.search(text))


def scan(src):
    """Return (keywords, ambiguous_at): the lowercase reserved keywords as
    (start, end, word), and the offset of the first ambiguous string (or
    None). Scanning stops at the first ambiguous string."""
    toks = tokens(src)
    keywords, prev = [], ""
    for i, (kind, start, end, text) in enumerate(toks):
        if kind == COMMENT:
            continue  # comments are whitespace: keep the previous token
        if kind == LITERAL and is_ambiguous_string(text):
            return keywords, start
        if kind in (LITERAL, META):
            prev = ""
            continue
        low = text.lower()
        if low in KEYWORDS and text != text.upper() and prev not in (".", "as", ":"):
            nxt = next((t for k, _, _, t in toks[i + 1:] if k != COMMENT), "")
            if not (KEYWORDS[low] == "T" and nxt == "("):
                keywords.append((start, end, text))
        prev = low
    return keywords, None


def uppercase(src, keywords):
    """Return src with exactly the given keyword spans uppercased."""
    out, last = [], 0
    for start, end, text in keywords:
        out += [src[last:start], text.upper()]
        last = end
    out.append(src[last:])
    new = "".join(out)
    assert new.lower() == src.lower(), "non case-only change"
    return new


def line_of(src, pos):
    return src.count("\n", 0, pos) + 1


def repo_root(arg):
    if arg:
        return Path(arg)
    root = Path(__file__).resolve().parent.parent
    if not (root / "sql" / "variables.sql").is_file():
        top = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
        if top.returncode == 0:
            root = Path(top.stdout.strip())
    return root


def main(argv):
    fix = "--fix" in argv
    args = [a for a in argv if a != "--fix"]
    root = repo_root(args[0] if args else None)
    if not (root / "sql" / "variables.sql").is_file():
        print(f"error: {root} doesn't look like the pg_scripts repository "
              "(sql/variables.sql not found)", file=sys.stderr)
        return 2

    problems = fixed = unfixed = 0
    files = sorted(root.glob("sql/*.sql")) + sorted(root.glob("reports/*.sql"))
    for path in files:
        rel = path.relative_to(root)
        with open(path, newline="") as f:
            src = f.read()
        keywords, ambiguous_at = scan(src)
        if ambiguous_at is not None:
            print(f"{rel}:{line_of(src, ambiguous_at)}: string with a backslash before its "
                  "closing quote is ambiguous across standard_conforming_strings; "
                  "use '' or E'...' (rest of this file not checked)")
            problems += 1
        if not keywords:
            continue
        if fix and ambiguous_at is not None:
            print(f"{rel}: not fixed ({len(keywords)} keyword(s)) until the ambiguous "
                  "string above is rewritten")
            unfixed += len(keywords)
        elif fix:
            with open(path, "w", newline="") as f:
                f.write(uppercase(src, keywords))
            print(f"{rel}: uppercased {len(keywords)} keyword(s)")
            fixed += len(keywords)
        else:
            for start, _, text in keywords:
                print(f"{rel}:{line_of(src, start)}: keyword '{text}' should be "
                      f"uppercase ({text.upper()})")
            problems += len(keywords)

    if fix:
        if fixed:
            print(f"\nFixed {fixed} keyword(s)")
        if problems or unfixed:
            print(f"{problems} ambiguous string(s) to rewrite by hand; "
                  f"{unfixed} keyword(s) left unfixed")
            return 1
        if not fixed:
            print("All keywords OK")
        return 0
    if problems:
        print(f"\n{problems} problem(s) found (run ./tools/check_keywords.py --fix "
              "to fix the keywords)")
        return 1
    print("All keywords OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
