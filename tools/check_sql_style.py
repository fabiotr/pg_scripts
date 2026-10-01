#!/usr/bin/env python3
"""Check the SQL style rules of a repository's .sql files (see CLAUDE.md
and CONTRIBUTING.md):

1. Reserved keywords are UPPERCASE. "Reserved" means PostgreSQL's own
   list: pg_get_keywords() categories R (reserved) and T (reserved, can be a
   function or type name), taken from PostgreSQL 15, plus SYSTEM_USER
   (reserved since 16). The second word of PRIMARY KEY, FOREIGN KEY,
   ORDER BY and GROUP BY follows the first one.
2. Unquoted identifiers are lowercase: table, column, alias, schema and
   function names, PL/pgSQL variables, EXTRACT fields such as epoch. A word
   is an identifier when it isn't a PostgreSQL keyword of any category;
   unreserved and column-name keywords (name, type, text, numeric,
   coalesce, ...) can't be told apart from identifiers without a full
   parser, so their case is free, and so is the case of role options and
   privilege names that aren't keywords (LOGIN, NOLOGIN, USAGE, CONNECT).
   Words right after '.' are always identifiers. A reserved word right
   after AS is a column alias (free case) only when followed by ',', ')',
   ';', FROM or the end (SELECT 1 AS order FROM t); otherwise it's syntax
   (CREATE VIEW v AS SELECT ...) and must be uppercase.
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
5. Plain '...' strings have no backslashes: with standard_conforming_strings
   off (the default up to 9.0) '\\s+' means s+. --fix rewrites them as the
   equivalent E'...' ('\\s+' -> E'\\\\s+'); E'...', U&'...' and dollar
   literals are not affected. A backslash right before one of the quotes
   ('a\\', 'can\\'t', 'a\\\'\'') is reported as ambiguous instead, since
   even where the string ends depends on that setting; nothing after it in
   that file is checked.

Case is never checked or changed inside strings ('...', E'...') and $$...$$
/ $tag$...$tag$ text literals (e.g. to_char patterns, where 'Month' and
'MONTH' differ), "quoted" identifiers, -- and /* */ comments (nested ones
too), psql \\meta-command lines and psql variables (:name, :{?name}).

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

To run it before every commit:
  printf '#!/bin/sh\\n./tools/check_sql_style.py\\n' > .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
(in fabiotr/pg_scripts, chain it with the dispatcher check:
 ./tools/check_dispatchers.sh && ./tools/check_sql_style.py)

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
# added in 16 and 17 (JSON syntax, MERGE_ACTION, ...) and 18 (ENFORCED,
# PERIOD, VIRTUAL). Their case is free.
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
unconditional
enforced period virtual""".split()
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
# After AS, a reserved keyword followed by one of these (the end of a target
# list item) is a column alias (SELECT 1 AS order, 2 AS desc FROM t WHERE ...);
# otherwise it's syntax that must be uppercase (CREATE VIEW v AS SELECT ...,
# CREATE TABLE t AS TABLE u)
ALIAS_FOLLOWERS = {",", ")", ";", "", "from", "where", "group", "order", "having",
                   "window", "limit", "offset", "fetch", "for", "union", "intersect",
                   "except", "into", "returning"}

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
# Prefix of a quoted language name: LANGUAGE E'plpgsql', U&'sql'
LITERAL_PREFIX_RE = re.compile(r"^(?:[EeNn]|[Uu]&)(?=['\"])")
# Tags of a dollar-quoted language name: LANGUAGE $l$plpgsql$l$
DOLLAR_LANGUAGE_RE = re.compile(r"^(\$[^$]*\$)(.*)\1$", re.S)
# Words that start a function option (or the body): never a language name
FUNCTION_OPTIONS = {"as", "set", "support", "cost", "rows", "security", "strict",
                    "immutable", "stable", "volatile", "parallel", "leakproof",
                    "window", "called", "returns", "transform", "not", "external",
                    "begin", "return", "language", "reset"}

# Token kinds
COMMENT, LITERAL, META, WORD, NUMBER, OTHER = "comment", "literal", "meta", "word", "number", "other"
# Finding kinds
KEYWORD, IDENTIFIER, NON_ASCII, SPECIAL, BACKSLASH = (
    "keyword", "identifier", "non-ascii", "special", "backslash")
# Two-word phrases whose second word is an unreserved keyword but follows
# the reserved first one: PRIMARY KEY, FOREIGN KEY, ORDER BY, GROUP BY
PHRASES = {"key": {"primary", "foreign"}, "by": {"order", "group"}}

# PostgreSQL identifier characters: its lexer treats every non-ASCII
# character as a letter (ident_start/ident_cont in scan.l)
IDENT_START = r"[A-Za-z_\u0080-\U0010FFFF]"
IDENT_CONT = r"[A-Za-z0-9_\u0080-\U0010FFFF]"  # plus $, except in dollar-quote tags

# Opening $$ / $tag$ (tag: identifier rule); the closing one is found with
# str.find, so unterminated tags don't make scanning quadratic
DOLLAR_OPEN_RE = re.compile(r"\$(?:" + IDENT_START + IDENT_CONT + r"*)?\$")
LITERAL_RE = re.compile(
    r"[Ee]'(?:\\.|''|[^'\\])*'"                  # E'...' string (backslash escapes; the
                                                  # classes are disjoint to avoid ReDoS)
    r"|[Uu]&'(?:''|[^'])*'"                       # U&'...' Unicode string
    r"|[Uu]&\"[^\"]*\""                            # U&"..." Unicode identifier
    r"|[BbXx]'[^']*'"                             # B'1010' / X'CAFE' bit strings
    r"|[Nn]?'(?:''|[^'])*'"                       # '...' and N'...' strings
    r"|\"[^\"]*\"",                               # "quoted" identifier
    re.S)
# Numeric constants, so that the E of 1E10 or the X of 0X1F isn't read as
# an identifier (hex/octal/binary and _ separators since PostgreSQL 16)
NUMBER_RE = re.compile(
    r"0[xX][0-9A-Fa-f_]+|0[oO][0-7_]+|0[bB][01_]+"
    r"|(?:[0-9][0-9_]*(?:\.[0-9_]*)?|\.[0-9][0-9_]*)(?:[eE][+-]?[0-9][0-9_]*)?")
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
        elif (m := DOLLAR_OPEN_RE.match(src, pos, endpos)):
            close = src.find(m.group(0), m.end(), endpos)  # unterminated: rest of range
            end, kind = (endpos if close < 0 else close + len(m.group(0))), LITERAL
        elif (m := LITERAL_RE.match(src, pos, endpos)):
            end, kind = m.end(), LITERAL
        elif (m := NUMBER_RE.match(src, pos, endpos)):
            end, kind = m.end(), NUMBER
        elif (m := WORD_RE.match(src, pos, endpos)):
            end, kind = m.end(), WORD
        else:
            end, kind = pos + 1, OTHER
        out.append((kind, pos, end, src[pos:end]))
        pos = end
    return out


def plain_string_body(text):
    """The content of a plain '...' or N'...' literal, or None for any other
    token (E'...', U&'...', B'...', $$...$$, "..." are not plain strings)."""
    if text[:1] == "'":
        return text[1:-1]
    if text[:2] in ("N'", "n'"):
        return text[2:-1]
    return None


def is_ambiguous_string(text):
    """True for a plain string whose end depends on standard_conforming_strings
    (a quote preceded by an odd number of backslashes)."""
    body = plain_string_body(text)
    return body is not None and bool(ESCAPED_QUOTE_RE.search(body + "'"))


def backslash_fix(text):
    """For a plain string containing backslashes, whose value depends on
    standard_conforming_strings ('\\s+' is \\s+ with it on, s+ with it off):
    the equivalent E'...' string (None for N'...', which has no E form)."""
    body = plain_string_body(text)
    if body is None or "\\" not in body:
        return None
    return "E'" + body.replace("\\", "\\\\") + "'" if text[0] == "'" else text


def statement_span(toks, i):
    """Tokens of the statement around toks[i] (from the previous ';' to the
    next one, comments dropped), split into (before, after)."""
    start = i
    while start > 0 and toks[start - 1][3] != ";":
        start -= 1
    end = i + 1
    while end < len(toks) and toks[end][3] != ";":
        end += 1
    keep = lambda span: [t for t in span if t[0] != COMMENT]
    return keep(toks[start:i]), keep(toks[i + 1:end])


def language_clause(span):
    """The name in the last LANGUAGE clause of span. Function options come
    after the argument list and RETURNS, so a parameter or column named
    language (f(language text)) never wins."""
    found = None
    for j, (kind, _, _, text) in enumerate(span[:-1]):
        nkind, _, _, name = span[j + 1]
        qualified = j > 0 and span[j - 1][3] == "."  # SET app.language TO ...
        # a language name can't be AS or another function option, so
        # SUPPORT language AS, SET search_path TO language SECURITY ... etc.
        # aren't clauses, whatever comes before them
        if (kind == WORD and text.lower() == "language" and not qualified
                and nkind in (WORD, LITERAL) and name.lower() not in FUNCTION_OPTIONS):
            name = DOLLAR_LANGUAGE_RE.sub(r"\2", name)
            found = LITERAL_PREFIX_RE.sub("", name).strip("'\"").lower()
    return found


def body_language(toks, i):
    """Language of the dollar-quoted literal toks[i] when it's the body of
    CREATE [OR REPLACE] FUNCTION|PROCEDURE ... AS $$...$$ or of DO $$...$$
    (None when it's just text)."""
    # Cheap check first: a body comes right after AS, DO or DO LANGUAGE x.
    # Only those literals pay for scanning the whole statement, so a
    # statement with many text literals stays linear.
    prior = []
    for j in range(i - 1, -1, -1):
        if toks[j][0] != COMMENT:
            prior.append(toks[j][3].lower())
            if len(prior) == 3:
                break
    if not (prior[:1] in (["as"], ["do"]) or prior[1:3] == ["language", "do"]):
        return None
    before, after = statement_span(toks, i)
    words = [t.lower() for k, _, _, t in before if k == WORD]
    last = [t.lower() for _, _, _, t in before[-3:]]
    language = language_clause(before + after)
    if last[-1:] == ["do"] or last[-3:-1] == ["do", "language"]:
        return language or "plpgsql"
    head = [w for w in words if w not in ("or", "replace")][:2]
    if head[:1] == ["create"] and head[1:2] in (["function"], ["procedure"]) and last[-1:] == ["as"]:
        return language
    return None


def is_psql_variable(src, start):
    """True when the word at start is written as psql's :name or :{?name},
    i.e. directly after ':' (but not '::', a cast) or ':{?' with nothing in
    between, so a[1: Upper] or ': /* x */ Upper' aren't psql variables."""
    if src[start - 3:start] == ":{?":
        return True
    return start >= 1 and src[start - 1] == ":" and (start < 2 or src[start - 2] != ":")


def next_significant(toks, i):
    """Text of the first non-comment token after toks[i], walking by index
    instead of copying the rest of the list. "" at the end, and also at a
    psql \\meta line: \\gset, \\g, ... end the query in front of them."""
    for j in range(i + 1, len(toks)):
        if toks[j][0] == META:
            return ""
        if toks[j][0] != COMMENT:
            return toks[j][3]
    return ""


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
    prev = ""
    for i, (kind, start, end, text) in enumerate(toks):
        if kind == COMMENT:
            continue  # comments are whitespace: keep the previous token
        if kind == LITERAL:
            if is_ambiguous_string(text):
                return start
            fixed = backslash_fix(text)
            if fixed is not None:
                findings.append((start, end, text, BACKSLASH, None if fixed == text else fixed))
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
            prev = ""
            continue
        low = text.lower()
        # :name and :{?name} are psql variables (top level only; psql doesn't
        # touch bodies), but ::type is a cast
        skip = mode == "top" and is_psql_variable(src, start)
        if kind == WORD and not skip:
            nxt = next_significant(toks, i)
            if NON_ASCII_RE.search(text):
                findings.append((start, end, text, NON_ASCII, None))
            elif low in special and prev != ".":
                if text != text.upper():
                    findings.append((start, end, text, SPECIAL, text.upper()))
            elif prev == "." or (low in FUNCTIONS and nxt == "(") \
                    or (low not in reserved and low not in free):
                if text != low:
                    findings.append((start, end, text, IDENTIFIER, low))
            elif prev == "as" and nxt.lower() in ALIAS_FOLLOWERS:
                pass  # AS order, ...: a reserved word used as a column alias
            elif (low in reserved or prev in PHRASES.get(low, ())) and text != text.upper():
                findings.append((start, end, text, KEYWORD, text.upper()))
        prev = low
    return None


def apply_fixes(src, findings):
    """Return src with every fixable finding corrected: the case of words,
    and plain strings with backslashes rewritten as the equivalent E'...'."""
    out, last = [], 0
    for start, end, text, kind, fixed in sorted(findings):
        if fixed is None:
            continue
        if kind == BACKSLASH:
            assert fixed == "E'" + text[1:-1].replace("\\", "\\\\") + "'", "bad E'' rewrite"
        else:
            assert fixed.lower() == text.lower(), "non case-only change"
        out += [src[last:start], fixed]
        last = end
    out.append(src[last:])
    return "".join(out)


def message(text, kind, fixed):
    if kind == KEYWORD:
        return f"keyword '{text}' should be uppercase ({fixed})"
    if kind == IDENTIFIER:
        return f"identifier '{text}' should be lowercase ({fixed})"
    if kind == SPECIAL:
        return f"PL/pgSQL special variable '{text}' should be uppercase ({fixed})"
    if kind == BACKSLASH:
        how = f"use {fixed}" if fixed else "use an E'...' string"
        return (f"string {text[:40]}{'...' if len(text) > 40 else ''} has a backslash, whose meaning "
                f"depends on standard_conforming_strings; {how}")
    return (f"non-ASCII character in the unquoted identifier or dollar-quote tag "
            f"'{text}'; use ASCII, or quote the identifier")


def line_of(src, pos):
    return src.count("\n", 0, pos) + 1


def default_root():
    """The repository this script is invoked from (tools/..), or the git top
    level when that isn't a repository (e.g. run from .git/hooks). The path
    isn't resolved, so a tools/check_sql_style.py symlink in another
    repository checks that repository, not the one the link points to."""
    root = Path(__file__).absolute().parent.parent
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
            print(f"{rel}: fixed {len(fixable)} item(s)")
            fixed += len(fixable)
            findings = [f for f in findings if f[4] is None]
        elif fix and fixable:
            print(f"{rel}: not fixed ({len(fixable)} item(s)) until the ambiguous "
                  "string above is rewritten")
        for start, _, text, kind, fixed_text in findings:
            print(f"{rel}:{line_of(src, start)}: {message(text, kind, fixed_text)}")
        problems += len(findings)

    if fixed:
        print(f"\nFixed {fixed} item(s)")
    if problems:
        hint = "" if fix else (" (run ./tools/check_sql_style.py --fix to fix the case of keywords"
                               " and identifiers and rewrite backslash strings as E'...')")
        print(f"\n{problems} problem(s) found{hint}")
        return 1
    print("All SQL style checks OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
