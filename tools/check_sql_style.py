#!/usr/bin/env python3
"""Check the SQL style rules of sql/*.sql and reports/*.sql (see CLAUDE.md
and CONTRIBUTING.md):

1. Reserved keywords are UPPERCASE. "Reserved" means PostgreSQL's own
   list: pg_get_keywords() categories R (reserved) and T (reserved, can be a
   function or type name), taken from PostgreSQL 15, plus SYSTEM_USER
   (reserved since 16).
2. Unquoted identifiers are lowercase: table, column, alias, schema and
   function names, PL/pgSQL variables, EXTRACT fields such as epoch. A word
   is an identifier when it isn't a PostgreSQL keyword of any category;
   unreserved and column-name keywords (name, type, text, numeric,
   coalesce, ...) can't be told apart from identifiers without a full
   parser, so their case is free. Words right after '.' are always
   identifiers; a keyword right after AS may be an alias or syntax
   (CREATE VIEW v AS SELECT, CAST(x AS integer)), so it's not checked.
3. Unquoted identifiers and dollar-quote tags are ASCII-only: PostgreSQL
   case-folds non-ASCII letters differently depending on the server
   encoding, and client encodings may not convert them.

Never checked, because case is part of the value there or it's not SQL:
  - strings ('...', E'...') and $$...$$ / $tag$...$tag$ literals (e.g.
    to_char patterns, where 'Month' and 'MONTH' differ), "quoted"
    identifiers, -- and /* */ comments (nested ones too), psql
    \\meta-command lines, psql variables (:name)

A plain '...' string with a backslash right before one of its quotes
('a\\', 'can\\'t' or 'a\\''') is reported as ambiguous: where it ends
depends on standard_conforming_strings (off by default up to 9.0, on since
9.1). Nothing after it in that file is checked, since token boundaries are
unknown from there on.

Requirements: python3 (standard library only).

Usage:
  ./tools/check_sql_style.py [--fix] [repo_dir]
  (repo_dir defaults to the parent directory of this script)
  --fix  rewrites the files in place, fixing the case of the reported
         keywords and identifiers; non-ASCII identifiers/tags are left for
         you, and files with an ambiguous string are left untouched

Exit code: 0 when everything is fine (or --fix fixed everything), 1 when
any problem is left. Problems are printed as "file:line: message".

To run it before every commit, together with the dispatcher check:
  printf '#!/bin/sh\\n./tools/check_dispatchers.sh && ./tools/check_sql_style.py\\n' > .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit

The tokenizer treats non-ASCII characters as identifier letters, as
PostgreSQL's lexer does, so selecté or $café$...$café$ are single tokens
(and get one "non-ASCII" report instead of a misleading keyword report).
"""

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
# Unreserved (U) and column-name (C) keywords of PostgreSQL 15, plus the ones
# added in 16 and 17 (JSON syntax, MERGE_ACTION, ...). Their case is free.
OTHER_KEYWORDS = """abort absolute access action add admin after aggregate also alter always
asensitive assertion assignment at atomic attach attribute backward before begin
breadth by cache call called cascade cascaded catalog chain characteristics
checkpoint class close cluster columns comment comments commit committed
compression configuration conflict connection constraints content continue
conversion copy cost csv cube current cursor cycle data database day deallocate
declare defaults deferred definer delete delimiter delimiters depends depth
detach dictionary disable discard document domain double drop each enable
encoding encrypted enum escape event exclude excluding exclusive execute explain
expression extension external family filter finalize first following force
forward function functions generated global granted groups handler header hold
hour identity if immediate immutable implicit import include including increment
index indexes inherit inherits inline input insensitive insert instead invoker
isolation key label language large last leakproof level listen load local
location lock locked logged mapping match matched materialized maxvalue merge
method minute minvalue mode month move name names new next nfc nfd nfkc nfkd no
normalized nothing notify nowait nulls object of off oids old operator option
options ordinality others over overriding owned owner parallel parameter parser
partial partition passing password plans policy preceding prepare prepared
preserve prior privileges procedural procedure procedures program publication
quote range read reassign recheck recursive ref referencing refresh reindex
relative release rename repeatable replace replica reset restart restrict return
returns revoke role rollback rollup routine routines rows rule savepoint schema
schemas scroll search second security sequence sequences serializable server
session set sets share show simple skip snapshot sql stable standalone start
statement statistics stdin stdout storage stored strict strip subscription
support sysid system tables tablespace temp template temporary text ties
transaction transform trigger truncate trusted type types uescape unbounded
uncommitted unencrypted unknown unlisten unlogged until update vacuum valid
validate validator value varying version view views volatile whitespace within
without work wrapper write xml year yes zone
between bigint bit boolean char character coalesce dec decimal exists extract
float greatest grouping inout int integer interval least national nchar none
normalize nullif numeric out overlay position precision real row setof smallint
substring time timestamp treat trim values varchar xmlattributes xmlconcat
xmlelement xmlexists xmlforest xmlnamespaces xmlparse xmlpi xmlroot
xmlserialize xmltable
absent format json json_array json_arrayagg json_object json_objectagg keys
scalar
conditional empty error json_exists json_query json_scalar json_serialize
json_table json_value keep merge_action nested omit path quotes string
unconditional""".split()
KEYWORDS = {w: "R" for w in RESERVED} | {w: "T" for w in FUNC_OR_TYPE}
ALL_KEYWORDS = set(KEYWORDS) | set(OTHER_KEYWORDS)
# Category-T keywords that PostgreSQL also has as functions: when called
# (next token "("), they are function names, i.e. lowercase identifiers.
# Other T words before "(" are SQL syntax: join (...), like (...).
FUNCTIONS = {"left", "right", "current_schema"}

# Token kinds
COMMENT, LITERAL, META, WORD, OTHER = "comment", "literal", "meta", "word", "other"
# Finding kinds
KEYWORD, IDENTIFIER, NON_ASCII = "keyword", "identifier", "non-ascii"

# PostgreSQL identifier characters: its lexer treats every non-ASCII
# character as a letter (ident_start/ident_cont in scan.l)
IDENT_START = r"[A-Za-z_\u0080-\U0010FFFF]"
IDENT_CONT = r"[A-Za-z0-9_\u0080-\U0010FFFF]"  # plus $, except in dollar-quote tags

LITERAL_RE = re.compile(
    r"\$((?:" + IDENT_START + IDENT_CONT + r"*)?)\$.*?\$\1\$"  # $$...$$ / $tag$...$tag$
    r"|[Ee]'(?:\\.|''|[^'\\])*'"                  # E'...' string (backslash escapes; the
                                                  # classes are disjoint to avoid ReDoS)
    r"|'(?:''|[^'])*'"                            # '...' string
    r"|\"[^\"]*\"",                               # "quoted" identifier
    re.S)
DOLLAR_TAG_RE = re.compile(r"\$[^$]*\$")
WORD_RE = re.compile(IDENT_START + r"(?:" + IDENT_CONT + r"|\$)*")
SPACE_RE = re.compile(r"\s+")
NON_ASCII_RE = re.compile(r"[^\x00-\x7f]")
# A quote preceded by an odd number of backslashes: inside a plain string
# (at its end or at a doubled '' quote) its meaning depends on
# standard_conforming_strings
ESCAPED_QUOTE_RE = re.compile(r"(?<!\\)(?:\\\\)*\\'")


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
    return text[0] == "'" and bool(ESCAPED_QUOTE_RE.search(text, 1))


def scan(src):
    """Return (findings, ambiguous_at). findings are (start, end, text,
    kind, fixed_text) with kind KEYWORD, IDENTIFIER or NON_ASCII (fixed_text
    is None for NON_ASCII); ambiguous_at is the offset of the first
    ambiguous string, or None. Scanning stops at the first ambiguous string."""
    toks = tokens(src)
    findings, prev, prev2 = [], "", ""
    for i, (kind, start, end, text) in enumerate(toks):
        if kind == COMMENT:
            continue  # comments are whitespace: keep the previous token
        if kind == LITERAL:
            if is_ambiguous_string(text):
                return findings, start
            if text[0] == "$":
                tag = DOLLAR_TAG_RE.match(text).group(0)
                if NON_ASCII_RE.search(tag):
                    findings.append((start, start + len(tag), tag, NON_ASCII, None))
        if kind in (LITERAL, META):
            prev = prev2 = ""
            continue
        low = text.lower()
        psql_variable = prev == ":" and prev2 != ":"  # :name, but not ::type
        if kind == WORD and not psql_variable:
            nxt = next((t for k, _, _, t in toks[i + 1:] if k != COMMENT), "")
            if NON_ASCII_RE.search(text):
                findings.append((start, end, text, NON_ASCII, None))
            elif prev == "." or (low in FUNCTIONS and nxt == "(") \
                    or low not in ALL_KEYWORDS:
                if text != low:
                    findings.append((start, end, text, IDENTIFIER, low))
            elif prev == "as":
                pass  # a keyword after AS may be an alias or syntax (AS SELECT)
            elif low in KEYWORDS and text != text.upper():
                findings.append((start, end, text, KEYWORD, text.upper()))
        prev2, prev = prev, low
    return findings, None


def apply_fixes(src, findings):
    """Return src with the case of every fixable finding corrected."""
    out, last = [], 0
    for start, end, _, _, fixed in findings:
        if fixed is None:
            continue
        out += [src[last:start], fixed]
        last = end
    out.append(src[last:])
    new = "".join(out)
    assert new.lower() == src.lower(), "non case-only change"
    return new


def message(text, kind, fixed):
    if kind == KEYWORD:
        return f"keyword '{text}' should be uppercase ({fixed})"
    if kind == IDENTIFIER:
        return f"identifier '{text}' should be lowercase ({fixed})"
    return (f"non-ASCII character in the unquoted identifier or dollar-quote tag "
            f"'{text}'; use ASCII, or quote the identifier")


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

    problems = fixed = 0
    files = sorted(root.glob("sql/*.sql")) + sorted(root.glob("reports/*.sql"))
    for path in files:
        rel = path.relative_to(root)
        with open(path, newline="", encoding="utf-8") as f:
            src = f.read()
        findings, ambiguous_at = scan(src)
        if ambiguous_at is not None:
            print(f"{rel}:{line_of(src, ambiguous_at)}: string with a backslash before one of "
                  "its quotes is ambiguous across standard_conforming_strings; "
                  "use '' or E'...' (rest of this file not checked)")
            problems += 1
        fixable = [f for f in findings if f[4] is not None]
        if fix and fixable and ambiguous_at is None:
            with open(path, "w", newline="", encoding="utf-8") as f:
                f.write(apply_fixes(src, findings))
            print(f"{rel}: fixed the case of {len(fixable)} word(s)")
            fixed += len(fixable)
            findings = [f for f in findings if f[4] is None]
        elif fix and fixable:
            print(f"{rel}: not fixed ({len(fixable)} word(s)) until the ambiguous "
                  "string above is rewritten")
        for start, _, text, kind, fixed_text in findings:
            print(f"{rel}:{line_of(src, start)}: {message(text, kind, fixed_text)}")
        problems += len(findings)

    if fixed:
        print(f"\nFixed {fixed} word(s)")
    if problems:
        hint = "" if fix else " (run ./tools/check_sql_style.py --fix to fix the case of keywords and identifiers)"
        print(f"\n{problems} problem(s) found{hint}")
        return 1
    print("All SQL style checks OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
