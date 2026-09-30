#!/usr/bin/env python3
"""Check the SQL style rules of a repository's .sql files (see CLAUDE.md
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
   parser, so their case is free, and so is the case of role options and
   privilege names that aren't keywords (LOGIN, NOLOGIN, USAGE, CONNECT). Words right after '.' are always
   identifiers; a keyword right after AS may be an alias or syntax
   (CREATE VIEW v AS SELECT, CAST(x AS integer)), so it's not checked.
3. Unquoted identifiers and dollar-quote tags are ASCII-only: PostgreSQL
   case-folds non-ASCII letters differently depending on the server
   encoding, and client encodings may not convert them.

4. Inside function bodies and DO blocks (CREATE [OR REPLACE] FUNCTION or
   PROCEDURE ... AS $$...$$, DO $$...$$) in LANGUAGE sql or plpgsql, which
   are scanned as code: PL/pgSQL reserved keywords (DECLARE, BEGIN, IF,
   LOOP, STRICT, ...) are UPPERCASE, its unreserved ones (RAISE, NOTICE,
   PERFORM, ...) have a free case, and its special variables (FOUND,
   SQLSTATE, SQLERRM, NEW, OLD, TG_OP, ...) are UPPERCASE. Bodies in other
   languages stay literals.

Never checked, because case is part of the value there or it's not SQL:
  - strings ('...', E'...') and $$...$$ / $tag$...$tag$ text literals (e.g.
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
  ./tools/check_sql_style.py [--fix] [--root DIR] [PATH_OR_GLOB ...]
  ./tools/check_sql_style.py [--fix] REPO_DIR
  DIR/REPO_DIR defaults to the repository this script is in. Files default
  to sql/*.sql and reports/*.sql in pg_scripts (a root with
  sql/variables.sql) and to every **/*.sql elsewhere.
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
# Syntax words that PostgreSQL's grammar reads as plain identifiers rather
# than keywords (role options, privilege names); like unreserved keywords,
# their case is free: CREATE ROLE r LOGIN, GRANT USAGE ON SCHEMA s.
SYNTAX_WORDS = """login nologin superuser nosuperuser createdb nocreatedb createrole
nocreaterole noinherit replication noreplication bypassrls nobypassrls usage
connect maintain""".split()
ALL_KEYWORDS = set(KEYWORDS) | set(OTHER_KEYWORDS) | set(SYNTAX_WORDS)
# Category-T keywords that PostgreSQL also has as functions: when called
# (next token "("), they are function names, i.e. lowercase identifiers.
# Other T words before "(" are SQL syntax: join (...), like (...).
FUNCTIONS = {"left", "right", "current_schema"}

# PL/pgSQL (inside function bodies and DO blocks in LANGUAGE plpgsql),
# from src/pl/plpgsql/src/pl_reserved_kwlist.h and pl_unreserved_kwlist.h.
# Reserved ones are UPPERCASE like SQL reserved keywords; unreserved ones
# have a free case.
PLPGSQL_RESERVED = """all begin by case declare else end execute for foreach from if in
into loop not null or strict then to using when while""".split()
PLPGSQL_UNRESERVED = """absolute alias and array assert backward call chain close collate
column column_name commit constant constraint constraint_name continue current
cursor datatype debug default detail diagnostics do dump elseif elsif errcode
error exception exit fetch first forward get hint import info insert is last log
merge message message_text move next no notice open option perform pg_context
pg_datatype_name pg_exception_context pg_exception_detail pg_exception_hint
pg_routine_oid print_strict_params prior query raise relative return
returned_sqlstate reverse rollback row_count rowtype schema schema_name scroll
slice sqlstate stacked table table_name type use_column use_variable
variable_conflict warning""".split()
# PL/pgSQL special variables: always UPPERCASE (repository convention)
PLPGSQL_SPECIAL = """found sqlstate sqlerrm new old tg_op tg_name tg_when tg_level
tg_relid tg_relname tg_table_name tg_table_schema tg_nargs tg_argv tg_event
tg_tag""".split()
CODE_LANGUAGES = {"sql", "plpgsql"}  # bodies in other languages stay literals

# Token kinds
COMMENT, LITERAL, META, WORD, OTHER = "comment", "literal", "meta", "word", "other"
# Finding kinds
KEYWORD, IDENTIFIER, NON_ASCII, SPECIAL = "keyword", "identifier", "non-ascii", "special"

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


def block_comment_end(src, pos, endpos):
    """End of the /* ... */ comment starting at pos. PostgreSQL block
    comments nest, so count the depth instead of stopping at the first */."""
    depth, i = 0, pos
    while i < endpos:
        if src.startswith("/*", i, endpos):
            depth += 1
            i += 2
        elif src.startswith("*/", i, endpos):
            depth -= 1
            i += 2
            if depth == 0:
                return i
        else:
            i += 1
    return endpos  # unterminated: rest of the range


def tokens(src, pos=0, endpos=None, meta=True):
    """Return every non-space token of src[pos:endpos] as (kind, start, end,
    text), with offsets into src. meta=False for function bodies, where psql
    doesn't process \\ commands."""
    endpos = len(src) if endpos is None else endpos
    out = []
    while pos < endpos:
        m = SPACE_RE.match(src, pos, endpos)
        if m:
            pos = m.end()
            continue
        if src.startswith("--", pos, endpos):
            end = src.find("\n", pos, endpos)
            end = endpos if end < 0 else end
            kind = COMMENT
        elif src.startswith("/*", pos, endpos):
            end, kind = block_comment_end(src, pos, endpos), COMMENT
        elif meta and src[pos] == "\\" and src[src.rfind("\n", 0, pos) + 1:pos].strip() == "":
            end = src.find("\n", pos, endpos)  # psql \\meta-command line
            end = endpos if end < 0 else end
            kind = META
        elif (m := LITERAL_RE.match(src, pos, endpos)):
            end, kind = m.end(), LITERAL
        elif (m := WORD_RE.match(src, pos, endpos)):
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


def statement_words(toks, i):
    """Lowercase words and punctuation of the statement around toks[i] (from
    the previous ';' to the next one), split into (before, after)."""
    start = i
    while start > 0 and toks[start - 1][3] != ";":
        start -= 1
    end = i + 1
    while end < len(toks) and toks[end][3] != ";":
        end += 1
    pick = lambda span: [t.lower().strip("'\"") for k, _, _, t in span if k != COMMENT]
    return pick(toks[start:i]), pick(toks[i + 1:end])


def body_language(toks, i):
    """Language of the dollar-quoted literal toks[i] when it's the body of
    CREATE [OR REPLACE] FUNCTION|PROCEDURE ... AS $$...$$ or of DO $$...$$
    (None when it's just text)."""
    before, after = statement_words(toks, i)
    words = before + after

    def language():
        for j, w in enumerate(words[:-1]):
            if w == "language":
                return words[j + 1]
        return None

    if before[-1:] == ["do"] or before[-3:-1] == ["do", "language"]:
        return language() or "plpgsql"
    head = [w for w in before if w not in ("or", "replace")][:2]
    if head[:1] == ["create"] and head[1:2] in (["function"], ["procedure"]) and before[-1:] == ["as"]:
        return language()
    return None


def scan(src):
    """Return (findings, ambiguous_at). findings are (start, end, text,
    kind, fixed_text) with kind KEYWORD, IDENTIFIER, SPECIAL or NON_ASCII
    (fixed_text is None for NON_ASCII); ambiguous_at is the offset of the
    first ambiguous string, or None. Scanning stops at the first ambiguous
    string. Function bodies and DO blocks in sql/plpgsql are scanned as code."""
    findings = []
    ambiguous_at = scan_tokens(src, tokens(src), "top", findings)
    return findings, ambiguous_at


def scan_tokens(src, toks, mode, findings):
    """Append the findings of toks (mode "top", "sql" or "plpgsql") to
    findings; return the offset of an ambiguous string, or None."""
    reserved = set(KEYWORDS) | (set(PLPGSQL_RESERVED) if mode == "plpgsql" else set())
    free = ALL_KEYWORDS | (set(PLPGSQL_UNRESERVED) if mode == "plpgsql" else set())
    special = set(PLPGSQL_SPECIAL) if mode == "plpgsql" else set()
    prev = prev2 = ""
    for i, (kind, start, end, text) in enumerate(toks):
        if kind == COMMENT:
            continue  # comments are whitespace: keep the previous token
        if kind == LITERAL:
            if is_ambiguous_string(text):
                return start
            if text[0] == "$":
                tag = DOLLAR_TAG_RE.match(text).group(0)
                if NON_ASCII_RE.search(tag):
                    findings.append((start, start + len(tag), tag, NON_ASCII, None))
                lang = body_language(toks, i)
                if lang in CODE_LANGUAGES:
                    body = tokens(src, start + len(tag), end - len(tag), meta=False)
                    at = scan_tokens(src, body, lang, findings)
                    if at is not None:
                        return at
        if kind in (LITERAL, META):
            prev = prev2 = ""
            continue
        low = text.lower()
        # :name is a psql variable (top level only; psql doesn't touch
        # bodies), but not ::type
        skip = mode == "top" and prev == ":" and prev2 != ":"
        if kind == WORD and not skip:
            nxt = next((t for k, _, _, t in toks[i + 1:] if k != COMMENT), "")
            if NON_ASCII_RE.search(text):
                findings.append((start, end, text, NON_ASCII, None))
            elif low in special and prev != ".":
                if text != text.upper():
                    findings.append((start, end, text, SPECIAL, text.upper()))
            elif prev == "." or (low in FUNCTIONS and nxt == "(") \
                    or (low not in reserved and low not in free):
                if text != low:
                    findings.append((start, end, text, IDENTIFIER, low))
            elif prev == "as":
                pass  # a keyword after AS may be an alias or syntax (AS SELECT)
            elif low in reserved and text != text.upper():
                findings.append((start, end, text, KEYWORD, text.upper()))
        prev2, prev = prev, low
    return None


def apply_fixes(src, findings):
    """Return src with the case of every fixable finding corrected."""
    out, last = [], 0
    for start, end, _, _, fixed in sorted(findings):
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
    if kind == SPECIAL:
        return f"PL/pgSQL special variable '{text}' should be uppercase ({fixed})"
    return (f"non-ASCII character in the unquoted identifier or dollar-quote tag "
            f"'{text}'; use ASCII, or quote the identifier")


def line_of(src, pos):
    return src.count("\n", 0, pos) + 1


def default_root():
    """The repository this script lives in (tools/..), or the git top level
    when it's run through a copy or symlink elsewhere (e.g. a git hook)."""
    root = Path(__file__).resolve().parent.parent
    if not (root / ".git").exists():
        top = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
        if top.returncode == 0:
            root = Path(top.stdout.strip())
    return root


def sql_files(root, patterns):
    """SQL files under root matching patterns (default: pg_scripts' sql/ and
    reports/ when root has sql/variables.sql, every *.sql otherwise)."""
    if not patterns:
        pg_scripts = (root / "sql" / "variables.sql").is_file()
        patterns = ["sql/*.sql", "reports/*.sql"] if pg_scripts else ["**/*.sql"]
    found = set()
    for pattern in patterns:
        path = root / pattern
        matches = [path] if path.is_file() else root.glob(pattern)
        found.update(m for m in matches if m.is_file() and ".git" not in m.relative_to(root).parts)
    return sorted(found)


def parse_args(argv):
    """[--fix] [--root DIR] [PATH_OR_GLOB ...]; a single directory argument
    is taken as the root."""
    fix, root, patterns, args = False, None, [], list(argv)
    while args:
        arg = args.pop(0)
        if arg == "--fix":
            fix = True
        elif arg == "--root" and args:
            root = Path(args.pop(0))
        else:
            patterns.append(arg)
    if root is None and len(patterns) == 1 and Path(patterns[0]).is_dir():
        root, patterns = Path(patterns[0]), []
    return fix, root or default_root(), patterns


def main(argv):
    fix, root, patterns = parse_args(argv)
    files = sql_files(root, patterns)
    if not files:
        print(f"error: no SQL files found under {root}", file=sys.stderr)
        return 2

    problems = fixed = 0
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
