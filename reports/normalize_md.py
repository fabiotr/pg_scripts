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
     '-', '+' and spaces, then data lines. A one-column table has no '|'
     at all: it's recognized by a header exactly as wide as its
     all-'-' separator, and its data lines start with a space.
  2) Expanded block (\\x auto), for single-row results: starts with
     "-[ RECORD N ]---...", followed by "key | value" lines.

Any other line (headings, \\qecho, [[_TOC_]], blank lines) passes through
unchanged, and so does everything inside a fenced code block the report
already opened itself (e.g. \\qecho '```sql' around generated commands).
"""
import argparse
import re
import sys
import unicodedata

RECORD_HEADER = re.compile(r'^-\[ RECORD \d+ \]')
FENCE = re.compile(r'^(`{3,}|~{3,})')
# \pset null used by report_*.sql, stripped
NULL_DISPLAY = '-'
# aligned-table separator: only '-', '+' and spaces, at least one '-'
SEP_LINE = re.compile(r'^[-+ ]*-[-+ ]*$')


def split_row(line: str):
    """Split a 'a | b | c' line into cells. Outer pipes are dropped only when
    the line itself starts with one (\\pset border 2): with border 1, a
    leading/trailing '|' after whitespace is the edge of an empty first/last
    cell, not a border."""
    s = line.rstrip()
    if s.startswith('|'):
        s = s[1:]
        if s.endswith('|'):
            s = s[:-1]
    return [c.strip() for c in s.split('|')]


def display_width(ch: str) -> int:
    """Terminal columns psql uses for ch: 2 for wide (CJK, most emoji),
    0 for combining marks and format characters, 1 otherwise."""
    if unicodedata.combining(ch) or unicodedata.category(ch) in ('Mn', 'Me', 'Cf'):
        return 0
    return 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1


def split_by_separator(line: str, sep: str):
    """Split a border-1 row at the columns where its separator line has '+',
    for rows whose data itself contains '|' (e.g. SQL's || operator). The
    separator is ASCII, so its indexes are display columns; the row is
    walked by display width. '|' left inside a cell is escaped for
    Markdown."""
    cuts = [k for k, c in enumerate(sep) if c == '+']
    cells, cur, col = [], [], 0
    for ch in line:
        if cuts and col == cuts[0] and ch == '|':
            cells.append(''.join(cur))
            cur = []
            cuts.pop(0)
        else:
            cur.append(ch)
        col += display_width(ch)
    cells.append(''.join(cur))
    return [c.strip().replace('\\', '\\\\').replace('|', '\\|') for c in cells]


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
        if not (
            lines[j].strip()
            and not lines[j].startswith('#')
            and not lines[j].startswith('-')
            and j + 1 < n
            and SEP_LINE.match(lines[j + 1])
        ):
            return False
        if '|' in lines[j]:
            return True
        # One column: " name " over a separator of the same display width
        # (psql pads by terminal columns: CJK/emoji count as 2), no '+'.
        # psql pads the header on both sides, so it ends with a space; data
        # rows aren't padded on the right, so two consecutive rows of equal
        # length (" ab" then " --") can't pass for a header + separator.
        # The only data row that ends with a space in these reports is the
        # ' - ' null display (\pset null ' - '), excluded explicitly.
        return (
            lines[j].startswith(' ')
            and lines[j].endswith(' ')
            and lines[j].strip() != NULL_DISPLAY
            and '+' not in lines[j + 1]
            and sum(map(display_width, lines[j])) == len(lines[j + 1])
        )

    def in_table(j, one_column=False):
        """True if lines[j] is still a data row of the current aligned table.
        psql doesn't always print a blank line between consecutive results,
        so the next table's header also ends the current one. A one-column
        row may be all hyphens (e.g. the ' - ' null display), so the
        separator check only applies to multi-column rows; it may also be
        just ' ' (an empty string value), so only a truly empty line ends a
        one-column table."""
        if one_column:
            return lines[j].startswith(' ') and not starts_table(j)
        if not lines[j].strip() or starts_table(j):
            return False
        return '|' in lines[j] and not SEP_LINE.match(lines[j])

    def end_md_table(j):
        """A Markdown table only ends at a blank line (GFM turns any other
        following line into one more row), and psql doesn't always print
        one between consecutive results, so add it when it's missing."""
        if j < n and lines[j].strip():
            out.append('')

    while i < n:
        line = lines[i]

        # ── Fenced code block opened by the report itself: copy it verbatim
        fence = FENCE.match(line)
        if fence:
            marker = fence.group(1)
            out.append(line)
            i += 1
            while i < n and not (lines[i].startswith(marker[0] * len(marker))
                                 and not lines[i].strip(marker[0]).strip()):
                out.append(lines[i])
                i += 1
            if i < n:
                out.append(lines[i])  # closing fence
                i += 1
            continue

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
                    # "key | value": split at the first '|' only, the value
                    # may itself contain pipes (e.g. SQL's ||)
                    key, value = row.split('|', 1)
                    out.append(to_md_row([key.strip(), value.strip().replace('|', '\\|')]))
                else:
                    out.append(row)
                i += 1
            end_md_table(i)
            continue

        # ── Aligned table: header + separator line + data lines
        if starts_table(i):
            one_column = '|' not in line
            if code:
                start = i
                i += 2
                while i < n and in_table(i, one_column):
                    i += 1
                out.extend(to_code_block(lines[start:i]))
                continue
            if one_column:
                # the value is a single cell: escape any '|' inside it
                cells_of = lambda l: [l.strip().replace('|', '\\|')]
            else:
                sep, ncols = lines[i + 1], lines[i + 1].count('+') + 1

                def cells_of(l, sep=sep, ncols=ncols):
                    cells = split_row(l)
                    return cells if len(cells) == ncols else split_by_separator(l, sep)
            header_cells = cells_of(line)
            out.append(to_md_row(header_cells))
            out.append('|' + '---|' * max(len(header_cells), 1))
            i += 2  # skip header + separator
            while i < n and in_table(i, one_column):
                out.append(to_md_row(cells_of(lines[i])))
                i += 1
            end_md_table(i)
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
