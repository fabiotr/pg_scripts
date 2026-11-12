#!/usr/bin/env python3
"""Checks the Markdown reports generate_reports.sh writes (-f md) for output
that shouldn't be there and for broken tables.

For each file it reports:
  - a psql row-count footer, "(N rows)" / "(1 row)": some included script
    turned \\pset footer back on
  - psql's own feedback: "Timing is on.", "Time: 12.3 ms", "Expanded display
    is ...", "Null display is ...", "Border style is ...", "Output format
    is ...", "Tuples only is ...", "Footer is ...", "Pager usage is ..."
  - a Markdown table row with more cells than its header (GFM drops them),
    or a short row written with its leading |, or a header whose second line
    is not the |---| separator (cells are
    counted as GitHub Markdown does: the pipes at both ends are optional, and
    a blank line, heading, fence, quote or list item ends the table)
  - a fenced code block (```) that is never closed

Requirements: Python 3.9+, standard library only. It reads files only, it
does not connect to any database.

Usage:
  ./tools/check_report_md.py REPORT.md [REPORT.md ...]

Problems are printed as "ERROR: file:line: message", the form
tools/check_battery.py reads. Exit code: 0 when every file is fine, 1 when
there is a problem, 2 when a file can't be read.
"""
import re
import sys
from pathlib import Path

FOOTER = re.compile(r"^\((\d+) rows?\)$")
FEEDBACK = re.compile(
    r"^(Timing is (on|off)\.|Time: \d|Expanded display is |Null display is |"
    r"Border style is |Output format is |Tuples only is |Footer is |"
    r"Pager usage is |Title is |Default footer is )")
SEPARATOR = re.compile(r"^\|(\s*:?-{3,}:?\s*\|)+\s*$")


def pipes(s):
    """Positions of the unescaped '|' in s ('\\|' and '\\\\' are escapes)."""
    out, i = [], 0
    while i < len(s):
        if s[i] == "\\":
            i += 2
            continue
        if s[i] == "|":
            out.append(i)
        i += 1
    return out


def cells(line):
    """Number of cells in a table row, as GFM counts them: the pipes at the
    start and at the end of the row are optional."""
    s = line.strip()
    p = pipes(s)
    n = len(p) + 1
    if p and p[0] == 0:
        n -= 1
    if p and p[-1] == len(s) - 1 and len(s) > 1:
        n -= 1
    return n


def ends_table(line):
    """A blank line or another block (heading, fence, quote, list) ends a GFM
    table; any other line is a row, with or without pipes at its ends."""
    s = line.strip()
    return not s or s.startswith(("#", "```", ">", "- ", "* "))


def check(path):
    problems = []
    lines = path.read_text(errors="replace").splitlines()
    fence = None  # line where an open ``` started
    table = None  # (header line number, cells)
    for no, raw in enumerate(lines, 1):
        line = raw.rstrip()
        if line.startswith("```"):
            fence = None if fence else no
            table = None
            continue
        if fence:
            continue  # code blocks keep psql's output as it was
        if FOOTER.match(line):
            problems.append((no, f"psql row-count footer {line!r}: \\pset footer is on"))
        elif FEEDBACK.match(line):
            problems.append((no, f"psql feedback in the report: {line[:60]!r}"))
        if table is not None and ends_table(line):
            table = None
        if table is None:
            if line.startswith("|"):  # a table starts: header, then the separator
                table = (no, cells(line))
        elif no == table[0] + 1:
            if not SEPARATOR.match(line):
                problems.append((no, "table header not followed by a |---| separator line"))
                table = None
            elif cells(line) != table[1]:
                problems.append((no, f"separator has {cells(line)} columns, its header (line {table[0]}) {table[1]}"))
        else:
            # GFM drops the cells past the header's count (data lost) and pads a
            # short row with empty ones; normalize_md writes every row with both
            # end pipes, so a short row starting with | is a defect too
            n = cells(line)
            if n > table[1] or (n < table[1] and line.startswith("|")):
                problems.append((no, f"table row has {n} columns, its header (line {table[0]}) {table[1]}"))
    if fence:
        problems.append((fence, "code block (```) never closed"))
    return problems


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if argv else 2
    bad = 0
    for name in argv:
        p = Path(name)
        try:
            found = check(p)
        except OSError as e:
            print(f"check_report_md: {e}", file=sys.stderr)
            return 2
        for no, msg in found:
            print(f"ERROR: {p}:{no}: {msg}")
        bad += len(found)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
