#!/usr/bin/env python3
"""Converts raw psql output (\\pset border 1, \\x auto) to valid markdown.

Usage:
    python3 normalize_md.py [--tables md|code] [raw.txt] > report.md
    psql -X service=<svc> -f <script>.sql > raw.txt && python3 normalize_md.py raw.txt > report.md
    psql -X service=<svc> -f <script>.sql | python3 normalize_md.py > report.md

--tables md (default) turns each psql table into a Markdown table.
--tables code keeps each psql table exactly as psql printed it (aligned
columns, numbers right-aligned) inside a fenced code block instead. A
whole table becomes a single code block, which renders much lighter than
a Markdown table in tools that store every table row as its own object
(e.g. Notion).

Handles two psql table forms:
  1) Aligned table (\\pset border 1): header line, a separator line of
     '-', '+' and spaces, then data lines.
  2) Expanded block (\\x auto), for single-row results: starts with
     "-[ RECORD N ]---...", followed by "key | value" lines.

Any other line (headings, \\qecho, [[_TOC_]], blank lines) passes through unchanged.
"""
import argparse
import re
import sys

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


def to_code_block(lines):
    """Wrap raw psql lines in a fence longer than any backtick run inside them."""
    longest = max((len(m) for l in lines for m in re.findall(r'`+', l)), default=0)
    fence = '`' * max(3, longest + 1)
    return [fence] + lines + [fence]


def normalize(text: str, tables: str = 'md') -> str:
    code = tables == 'code'
    lines = text.splitlines()
    out = []
    i = 0
    n = len(lines)

    def starts_table(j):
        """True if lines[j] is an aligned-table header (next line is its separator)."""
        return (
            lines[j].strip()
            and '|' in lines[j]
            and not lines[j].startswith('#')
            and not lines[j].startswith('-')
            and j + 1 < n
            and SEP_LINE.match(lines[j + 1])
        )

    def in_table(j):
        """True if lines[j] is still a data row of the current aligned table.
        psql doesn't always print a blank line between consecutive results,
        so the next table's header also ends the current one."""
        return (
            lines[j].strip()
            and '|' in lines[j]
            and not SEP_LINE.match(lines[j])
            and not starts_table(j)
        )

    while i < n:
        line = lines[i]

        # ── Expanded block: -[ RECORD N ]---+---
        if RECORD_HEADER.match(line) and code:
            # consecutive records (\x on, several rows) share one block
            start = i
            i += 1
            while i < n and (RECORD_HEADER.match(lines[i]) or in_table(i)):
                i += 1
            out.extend(to_code_block(lines[start:i]))
            continue

        if RECORD_HEADER.match(line):
            out.append('| Info | Value |')
            out.append('|---|---|')
            i += 1
            while i < n and lines[i].strip() and not RECORD_HEADER.match(lines[i]) and not starts_table(i):
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
        if starts_table(i):
            if code:
                start = i
                i += 2
                while i < n and in_table(i):
                    i += 1
                out.extend(to_code_block(lines[start:i]))
                continue
            header_cells = split_row(line)
            out.append(to_md_row(header_cells))
            out.append('|' + '---|' * max(len(header_cells), 1))
            i += 2  # skip header + separator
            while i < n and in_table(i):
                out.append(to_md_row(split_row(lines[i])))
                i += 1
            continue

        out.append(line)
        i += 1

    return '\n'.join(out) + '\n'


def main():
    parser = argparse.ArgumentParser(description='Convert raw psql output to Markdown.')
    parser.add_argument('--tables', choices=('md', 'code'), default='md',
                        help='render psql tables as Markdown tables (md, default) '
                             'or keep them as-is inside fenced code blocks (code)')
    parser.add_argument('file', nargs='?', help='raw psql output (default: stdin)')
    args = parser.parse_args()
    if args.file:
        with open(args.file, 'r') as f:
            text = f.read()
    else:
        text = sys.stdin.read()
    sys.stdout.write(normalize(text, args.tables))


if __name__ == '__main__':
    main()
