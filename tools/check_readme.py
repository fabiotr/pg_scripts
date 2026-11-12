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

ORDER = ["82", "83", "84", "90", "91", "92", "93", "94", "95", "96",
         "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"]
NOT_IN_CATALOG = {"variables.sql"}
VERSIONED = re.compile(r"_\d{2}(up|-)\.sql$")
ROW = re.compile(r"^\|[^|]*\|\s*`([^`]+\.sql)`\s*\|([^|]*)\|")
BRANCH = re.compile(r"^\s*\\(if|elif)\s+:svp_pg_(\d{2})\s*$")
ELSE = re.compile(r"^\s*\\else\s*$")
ENDIF = re.compile(r"^\s*\\endif\s*$")
IF = re.compile(r"^\s*\\if\b")


def label(v):
    """'82' -> '8.2', '96' -> '9.6', '10' -> '10'."""
    return v if v.startswith("1") else f"{v[0]}.{v[1]}"


def min_version(text):
    """Oldest version the dispatcher supports, or None for a file without
    svp_pg_VV branches (version-independent)."""
    depth, versions, else_text, in_else = 0, [], [], False
    for line in text.splitlines():
        if IF.match(line):
            depth += 1
            if depth == 1:
                m = BRANCH.match(line)
                if m:
                    versions.append(m.group(2))
                in_else = False
            continue
        if depth == 1:
            m = BRANCH.match(line)
            if m:
                versions.append(m.group(2))
                in_else = False
                continue
            if ELSE.match(line):
                in_else = True
                continue
        if ENDIF.match(line):
            depth -= 1
            if depth == 0:
                in_else = False
            continue
        if in_else and depth == 1:
            else_text.append(line)
    if not versions:
        return None
    if any(re.match(r"\s*\\ir?\s", l) for l in else_text):
        return "82"  # the \else branch still runs a query: every version
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
    rows = {}
    for no, line in enumerate(readme.read_text().splitlines(), 1):
        m = ROW.match(line)
        if m:
            rows.setdefault(m.group(1), (no, m.group(2)))
    for name, (no, cell) in rows.items():
        path = sql / name
        if not path.exists() and not (repo / "reports" / name).exists():
            problems.append(f"README.md:{no}: `{name}` is in the catalog but not in sql/ or reports/")
            continue
        if not path.exists():
            continue
        if re.fullmatch(r"\s*PG\s*<\s*[\d.]+\s*", cell):
            continue  # "PG < 12": up to a version (e.g. tables_with_oid)
        want = min_version(path.read_text())
        have = parse_cell(cell)
        if have is None:
            problems.append(f"README.md:{no}: `{name}`: version cell {cell.strip()!r} isn't \"PG >= X.Y\"")
        elif want is not None and have != want:
            problems.append(f"README.md:{no}: `{name}` says {cell.strip() or '(empty)'}, its dispatcher "
                            f"supports PG >= {label(want)}")
    for p in sorted(sql.glob("*.sql")):
        if VERSIONED.search(p.name) or p.name in NOT_IN_CATALOG:
            continue
        if p.name not in rows:
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
