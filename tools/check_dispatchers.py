#!/usr/bin/env python3
"""Checks the SQL dispatcher conventions described in CLAUDE.md.

For every sql/*.sql file (and reports/*.sql for includes only):
  - \\i is not used in sql/ (use \\ir, which resolves relative to the file)
  - every \\i / \\ir target exists
  - a branch `\\if :svp_pg_VV` / `\\elif :svp_pg_VV` includes <name>_VVup.sql
    (the version in the condition matches the version in the file name)
  - the svp_pg_* branches of an \\if chain go from newest to oldest version
  - every versioned file (<name>_VVup.sql, <name>_VV-.sql) is included by
    some script, i.e. no unreachable implementation
  - the fallback message is "\\qecho - Not supported on version ..." (capital N)

psql commands are found with check_sql_style.py's tokenizer, so a \\ line
inside a comment, a string or a $$ body is not taken as a command.

Requirements: Python 3.9+, standard library only (plus check_sql_style.py,
next to this file).

Usage:
  ./tools/check_dispatchers.py [repo_dir]
  (repo_dir defaults to the parent directory of this script, or the git top
  level when run through a symlink, e.g. .git/hooks/pre-commit)

Exit code: 0 when everything is fine, 1 when any problem is found, 2 when
repo_dir isn't the pg_scripts repository. Problems are printed as
"file:line: message".

To run it before every commit:
  ln -s ../../tools/check_dispatchers.py .git/hooks/pre-commit
"""
import re
import subprocess
import sys
from pathlib import Path

# check_sql_style.py lives next to the real file, also when this one is run
# through a symlink
sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_sql_style as ck  # noqa: E402

# Condition of an \if / \elif that is just a server version: \if :svp_pg_16
PG_CONDITION_RE = re.compile(r":svp_pg_([0-9]+)\s*$")
# \i / \ir and its target
INCLUDE_RE = re.compile(r"\\(ir?)\s+(\S+)")
# A versioned implementation: <name>_16up.sql, <name>_95-.sql
UP_FILE_RE = re.compile(r"_([0-9]+)up\.sql$")
VERSIONED_RE = re.compile(r"_[0-9]+(?:up|-)\.sql$")
LOWERCASE_MESSAGE = "\\qecho - not supported on version"


def version_num(v):
    """svp_pg_* / file name version suffix as a comparable number:
    82 -> 8.2, 96 -> 9.6, 10 -> 10."""
    n = int(v)
    return n / 10 if n >= 80 else n


def default_root():
    """The parent of this script's directory, or the git top level when that
    isn't the repository (e.g. run as .git/hooks/pre-commit)."""
    root = Path(__file__).absolute().parent.parent
    if not (root / "sql" / "variables.sql").is_file():
        top = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
        if top.returncode == 0:
            root = Path(top.stdout.strip())
    return root


def commands(src):
    """(line, text) of every psql \\ command line of src."""
    return [(ck.line_of(src, start), text)
            for kind, start, _, text in ck.tokens(src) if kind == ck.META]


def check_file(rel, src, existing, included, problem):
    """Checks one script; rel is its path relative to the repository."""
    folder = rel.split("/")[0]
    depth, cond, last = 0, {}, {}
    for line, text in commands(src):
        word = text[1:].split(None, 1)
        cmd, rest = (word[0], text) if word else ("", text)
        if cmd == "if" and len(word) > 1:
            depth += 1
            m = PG_CONDITION_RE.search(rest)
            cond[depth] = last[depth] = m.group(1) if m else ""
        elif cmd == "elif" and len(word) > 1:
            m = PG_CONDITION_RE.search(rest)
            cond[depth] = m.group(1) if m else ""
            if cond[depth] and last.get(depth) and \
                    version_num(cond[depth]) >= version_num(last[depth]):
                problem(rel, line, f"branch svp_pg_{cond[depth]} comes after svp_pg_{last[depth]} "
                                   "(branches must go from newest to oldest)")
            if cond[depth]:
                last[depth] = cond[depth]
        elif cmd == "else":
            cond[depth] = ""
        elif cmd == "endif":
            depth = max(depth - 1, 0)
        elif cmd in ("i", "ir") and (m := INCLUDE_RE.match(text)):
            target = m.group(2)
            if cmd == "i" and folder == "sql":
                problem(rel, line, f"uses \\i {target} (use \\ir, \\i only works when the "
                                   "current directory is sql/)")
            # Targets built from psql variables (e.g. :sql_dir) cannot be checked
            if ":" in target:
                continue
            name = target.rsplit("/", 1)[-1]
            included.add(name)
            if f"sql/{name}" not in existing and f"{folder}/{target}" not in existing:
                problem(rel, line, f"includes {target}, which does not exist")
            up = UP_FILE_RE.search(name)
            if up and depth > 0 and cond.get(depth) and up.group(1) != cond[depth]:
                problem(rel, line, f"branch svp_pg_{cond[depth]} includes {name} (version mismatch)")
        if LOWERCASE_MESSAGE in text:
            problem(rel, line, 'use "\\qecho - Not supported on version :svp_server_version" '
                               "(capital N)")


def main(argv):
    root = Path(argv[0]) if argv else default_root()
    if not (root / "sql" / "variables.sql").is_file():
        print(f"error: {root} doesn't look like the pg_scripts repository "
              "(sql/variables.sql not found)", file=sys.stderr)
        return 2

    scripts = sorted(root.glob("sql/*.sql")) + sorted(root.glob("reports/*.sql"))
    existing = {p.relative_to(root).as_posix() for p in scripts}
    included, problems = set(), []

    def problem(rel, line, msg):
        problems.append(f"{rel}:{line}: {msg}")

    for path in scripts:
        with open(path, newline="", encoding="utf-8") as f:
            check_file(path.relative_to(root).as_posix(), f.read(), existing, included, problem)

    for rel in sorted(existing):
        name = rel.rsplit("/", 1)[-1]
        if rel.startswith("sql/") and VERSIONED_RE.search(name) and name not in included:
            problems.append(f"{rel}: is not included by any script (unreachable)")

    if problems:
        print("\n".join(problems))
        print(f"\n{len(problems)} problem(s) found")
        return 1
    print("All dispatchers OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
