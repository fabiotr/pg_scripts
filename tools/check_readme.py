#!/usr/bin/env python3
"""Checks that the script catalog in README.md matches sql/.

  - every entry script in sql/ (a dispatcher or an unversioned file, not a
    <name>_VVup.sql / <name>_VV-.sql implementation) has a catalog row
  - every catalog row names a file that exists in sql/ or reports/
  - the "PG >= X.Y" cell matches the dispatcher: the oldest version among its
    top-level \\if / \\elif :svp_pg_VV branches, unless its \\else still
    includes a file (then every version); an empty cell and "PG >= 8.2" both
    mean 8.2, and a "PG < X" cell (a removed feature) isn't compared

A catalog row is a Markdown table row whose second cell is a `name.sql`
code span. variables.sql is not a user-facing script and needs no row.

Requirements: Python 3.9+, standard library only. No database.

Usage:
  ./tools/check_readme.py [repo_dir]
  (repo_dir defaults to the parent directory of this script)

Exit code: 0 when everything is fine, 1 when a problem is found, 2 when
repo_dir isn't the pg_scripts repository. Problems are printed as
"file:line: message".
"""
import re
import sys
from pathlib import Path

# check_sql_style.py lives next to this file: its tokenizer finds the psql
# commands outside comments and strings
sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_sql_style as ck  # noqa: E402

ORDER = ["82", "83", "84", "90", "91", "92", "93", "94", "95", "96",
         "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"]
NOT_IN_CATALOG = {"variables.sql"}
VERSIONED = re.compile(r"_\d{2}(up|-)\.sql$")
ROW = re.compile(r"^\|[^|]*\|\s*`([^`]+\.sql)`\s*\|([^|]*)\|")
BRANCH = re.compile(r"^\s*\\(if|elif)\s+:svp_pg_(\d{2})\s*$")
ELSE = re.compile(r"^\s*\\else\s*$")
ENDIF = re.compile(r"^\s*\\endif\s*$")
IF = re.compile(r"^\s*\\if\b")
INCLUDE = re.compile(r"^\s*\\ir?\s")


def label(v):
    """'82' -> '8.2', '96' -> '9.6', '10' -> '10'."""
    return v if v.startswith("1") else f"{v[0]}.{v[1]}"


def commands(src):
    """Text of every psql \\ command of src, skipping comments and strings."""
    return [text for kind, _, _, text in ck.tokens(src) if kind == ck.META]


def min_version(text):
    """Oldest version the dispatcher supports, or None for a file without
    svp_pg_VV branches (version-independent). Only top-level \\if chains with
    svp_pg_VV branches count; when the \\else of such a chain includes a file
    anywhere below it (e.g. inside a privilege check), every version runs."""
    depth, chain, versions, fallback = 0, None, [], False
    for cmd in commands(text):
        if IF.match(cmd):
            depth += 1
            if depth == 1:
                m = BRANCH.match(cmd)
                chain = {"versions": [m.group(2)] if m else [], "in_else": False, "includes": False}
            continue
        if depth == 1 and chain is not None:
            m = BRANCH.match(cmd)
            if m:
                chain["versions"].append(m.group(2))
                chain["in_else"] = False
                continue
            if ELSE.match(cmd):
                chain["in_else"] = True
                continue
        if ENDIF.match(cmd):
            depth -= 1
            if depth == 0 and chain is not None:
                if chain["versions"]:
                    versions += chain["versions"]
                    fallback = fallback or chain["includes"]
                chain = None
            continue
        if chain is not None and chain["in_else"] and INCLUDE.match(cmd):
            chain["includes"] = True
    if not versions:
        return None
    if fallback:
        return "82"  # a version chain's \\else still runs a query: every version
    return min(versions, key=ORDER.index)


def parse_cell(cell):
    """'PG >= 9.5' -> '95', 'PG >= 10' -> '10', '' or 'PG >= 8.2' -> '82'."""
    cell = cell.strip()
    if not cell:
        return "82"
    m = re.fullmatch(r"PG\s*>=\s*(\d+)(?:\.(\d+))?", cell)
    if not m:
        return None
    major, minor = m.group(1), m.group(2)
    return major if int(major) >= 10 else f"{major}{minor or '0'}"


def check(repo):
    problems = []
    readme = repo / "README.md"
    sql = repo / "sql"
    rows = []  # every row, so a duplicate row is checked too
    for no, line in enumerate(readme.read_text(encoding="utf-8").splitlines(), 1):
        m = ROW.match(line)
        if m:
            rows.append((m.group(1), no, m.group(2)))
    listed = {name for name, _, _ in rows}
    for name, no, cell in rows:
        path = sql / name
        if not path.exists() and not (repo / "reports" / name).exists():
            problems.append(f"README.md:{no}: `{name}` is in the catalog but not in sql/ or reports/")
            continue
        if not path.exists():
            continue
        if re.fullmatch(r"\s*PG\s*<\s*[\d.]+\s*", cell):
            continue  # "PG < 12": up to a version (e.g. tables_with_oid)
        want = min_version(path.read_text(encoding="utf-8"))
        have = parse_cell(cell)
        if have is None:
            problems.append(f"README.md:{no}: `{name}`: version cell {cell.strip()!r} isn't \"PG >= X.Y\"")
        elif want is not None and have != want:
            problems.append(f"README.md:{no}: `{name}` says {cell.strip() or '(empty)'}, its dispatcher "
                            f"supports PG >= {label(want)}")
    for p in sorted(sql.glob("*.sql")):
        if VERSIONED.search(p.name) or p.name in NOT_IN_CATALOG:
            continue
        if p.name not in listed:
            problems.append(f"sql/{p.name}:1: entry script missing from the README catalog")
    return problems


def main(argv):
    repo = Path(argv[0]) if argv else Path(__file__).absolute().parent.parent
    if not (repo / "README.md").is_file() or not (repo / "sql").is_dir():
        print(f"check_readme: {repo} is not the pg_scripts repository", file=sys.stderr)
        return 2
    problems = check(repo)
    for p in problems:
        print(p)
    if problems:
        return 1
    print("README catalog OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
