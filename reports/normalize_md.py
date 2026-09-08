#!/usr/bin/env python3
"""Converts raw psql output (\\pset border 1, \\x auto) to valid markdown.

Usage:
    python3 normalize_md.py raw.txt > report.md
    psql service=<svc> -f <script>.sql > raw.txt && python3 normalize_md.py raw.txt > report.md
    psql service=<svc> -f <script>.sql | python3 normalize_md.py > report.md

Handles two psql table forms:
  1) Aligned table (\\pset border 1): header line, a separator line of
     '-', '+' and spaces, then data lines.
  2) Expanded block (\\x auto), for single-row results: starts with
     "-[ RECORD N ]---...", followed by "key | value" lines.

Any other line (headings, \\qecho, [[_TOC_]], blank lines) passes through unchanged.
"""
import sys
import re

RECORD_HEADER = re.compile(r'^-\[ RECORD \d+ \]')
# aligned-table separator: only '-', '+' and spaces, at least one '-'
SEP_LINE = re.compile(r'^[-+ ]*-[-+ ]*$')


def split_row(line: str):
    """Split a 'a | b | c' line (with or without leading/trailing space/pipe) into cells."""
    s = line.strip()
    if s.startswith('|'):
        s = s[1:]
    if s.endswith('|'):
        s = s[:-1]
    return [c.strip() for c in s.split('|')]


def to_md_row(cells) -> str:
    return '| ' + ' | '.join(cells) + ' |'


def normalize(text: str) -> str:
    lines = text.splitlines()
    out = []
    i = 0
    n = len(lines)

    while i < n:
        line = lines[i]

        # ── Expanded block: -[ RECORD N ]---+---
        if RECORD_HEADER.match(line):
            out.append('| Info | Value |')
            out.append('|---|---|')
            i += 1
            while i < n and lines[i].strip() and not RECORD_HEADER.match(lines[i]):
                row = lines[i]
                if '|' in row:
                    cells = split_row(row)
                    # value may itself contain pipes; rejoin the rest
                    if len(cells) > 2:
                        cells = [cells[0], ' | '.join(cells[1:])]
                    out.append(to_md_row(cells))
                else:
                    out.append(row)
                i += 1
            continue

        # ── Aligned table: header + separator line + data lines
        if (
            line.strip()
            and '|' in line
            and not line.startswith('#')
            and not line.startswith('-')
            and i + 1 < n
            and SEP_LINE.match(lines[i + 1])
        ):
            header_cells = split_row(line)
            out.append(to_md_row(header_cells))
            out.append('|' + '---|' * max(len(header_cells), 1))
            i += 2  # skip header + separator
            while i < n and lines[i].strip() and '|' in lines[i] and not SEP_LINE.match(lines[i]):
                out.append(to_md_row(split_row(lines[i])))
                i += 1
            continue

        out.append(line)
        i += 1

    return '\n'.join(out) + '\n'


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            text = f.read()
    else:
        text = sys.stdin.read()
    sys.stdout.write(normalize(text))


if __name__ == '__main__':
    main()
