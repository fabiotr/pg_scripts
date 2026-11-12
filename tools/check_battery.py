#!/usr/bin/env python3
"""Checks the results of tools/run_battery.sh against tools/known_failures.csv.

A run is a problem when its output has an ERROR or FATAL line, it timed out,
psql exited with an error, or (for the REPORTS row) generate_reports.sh
failed. A results.csv with no runs, or without the END row run_battery.sh
writes last (an interrupted battery), is a problem too. A problem is known when tools/known_failures.csv has an entry for
that script and version whose pattern matches EVERY error line of the run, so
a second, new error in a script with a known one is still reported.

Requirements: Python 3.9+, standard library only. It reads files only, it
does not connect to any database.

Usage:
  ./tools/check_battery.py [--known FILE] [--strict] [--versions LIST] PATH [PATH ...]
  PATH: a results.csv, or a directory searched recursively for results.csv
  (e.g. one run_battery.sh output directory per version under one parent).
  --known   known failures file (default: known_failures.csv next to this script)
  --strict  also fail when a known failure no longer happens (stale entry)
  --versions LIST  versions that must have results ("82 83 10-18", or "all");
            one without any is a new problem (it never ran)

Exit code: 0 when every problem is known, 1 when there is a new problem (or a
stale entry with --strict), 2 when the input can't be read (a PATH that doesn't
exist or holds no results.csv).

It also reports a column that is empty in every row of a table with 2 or
more rows ('empty column "X" (all N rows)'): a value the script never gets;
and a "- Needs ..." line in a superuser run (rows without @low), where the
fixture installs every extension: a privilege or extension check gone wrong.

known_failures.csv columns: script,versions,pattern,reason
  script:   an entry for "x" also covers "x@low" (run_battery.sh --lowpriv);
            one for "x@low" only that pass
  versions: space-separated labels (82 83 ... 96 10 ... 18), ranges in that
            order (82-92) or "all"
  pattern:  Python regular expression searched in each message (error lines
            with the "psql:file:line: " prefix removed, empty columns); a run
            is known when each of its messages is matched by an entry for its
            script and version. Lines starting with # are comments.
"""
import argparse
import csv
import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

ORDER = ["82", "83", "84", "90", "91", "92", "93", "94", "95", "96",
         "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"]
PREFIX = re.compile(r"^psql:[^:]+:\d+: ")
# psql's own errors (an \ir to a missing file...): "psql:<file>:<line>: error: ..."
CLIENT_ERROR = re.compile(r"^psql:\S+: error:")


def vkey(v):
    return ORDER.index(v) if v in ORDER else len(ORDER)


def expand_versions(spec):
    """'82-84 10' -> {'82', '83', '84', '10'}; 'all' -> None (any version)."""
    if spec.strip() == "all":
        return None
    out = set()
    for tok in spec.split():
        if "-" in tok:
            a, b = tok.split("-", 1)
            if a not in ORDER or b not in ORDER or vkey(a) > vkey(b):
                raise ValueError(f"bad version range {tok!r}")
            out.update(ORDER[vkey(a):vkey(b) + 1])
        else:
            if tok not in ORDER:
                raise ValueError(f"unknown version {tok!r}")
            out.add(tok)
    return out


def read_known(path):
    entries = []
    with open(path, newline="") as f:
        lines = [l for l in f if l.strip() and not l.lstrip().startswith("#")]
    for i, row in enumerate(csv.DictReader(lines), 2):
        missing = {"script", "versions", "pattern"} - {k for k, v in row.items() if v}
        if missing:
            raise ValueError(f"{path}: entry {i}: missing {', '.join(sorted(missing))}")
        entries.append({"script": row["script"], "versions": expand_versions(row["versions"]),
                        "spec": row["versions"], "pattern": re.compile(row["pattern"]),
                        "reason": row.get("reason") or "", "hits": 0})
    return entries


def error_lines(path):
    if not path.exists():
        return []
    return [PREFIX.sub("", l.strip()) for l in path.open(errors="replace")
            if "ERROR:" in l or "FATAL:" in l or CLIENT_ERROR.match(l)]


SEP_ALIGNED = re.compile(r"^-+(\+-+)*$")
RECORD = re.compile(r"^-\[ RECORD \d+ \]")
FOOTER = re.compile(r"^\(\d+ rows?\)$")
EMPTY = ("", "-")  # psql's default null display, and the reports' ' - '


def display_width(ch):
    """Columns a character takes in psql's aligned output (as normalize_md.py):
    0 for combining marks and format characters, 2 for East Asian wide ones."""
    if unicodedata.combining(ch) or unicodedata.category(ch) in ("Mn", "Me", "Cf"):
        return 0
    return 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1


def cut(line, bounds):
    """Cells of one aligned line, split by display column (bounds come from the
    ---+--- line), and whether each one continues on the next line: psql puts
    a "+" in a cell's last column when its value has more lines."""
    cells, more, col = [[] for _ in bounds], [False] * len(bounds), 0
    for ch in line:
        for k, (a, b) in enumerate(bounds):
            if a <= col < b:
                if col == b - 1 and ch == "+":
                    more[k] = True
                else:
                    cells[k].append(ch)
                break
        col += display_width(ch)
    return ["".join(c).strip() for c in cells], any(more)


def tables(lines):
    """Yield (column names, rows) for each psql table in an output: aligned
    (header, then a ---+--- line) and expanded (\\x, -[ RECORD n ]- blocks).
    Rows are logical: the lines of a multi-line value are one row."""
    i = 0
    while i < len(lines):
        if i + 1 < len(lines) and lines[i].strip() and SEP_ALIGNED.match(lines[i + 1].strip()):
            sep, bounds, start = lines[i + 1].rstrip(), [], 0
            for k, ch in enumerate(sep + "+"):
                if ch == "+":
                    bounds.append((start, k))
                    start = k + 1
            heads, _ = cut(lines[i], bounds)
            j = i + 2
            # one column: a NULL row is a blank line, so when a "(N rows)" footer
            # follows, every line up to it is a row
            end = None
            if len(bounds) == 1:
                for k in range(j, len(lines)):
                    if FOOTER.match(lines[k].strip()):
                        end = k
                        break
                    if k + 1 < len(lines) and SEP_ALIGNED.match(lines[k + 1].strip()):
                        break  # another table starts first
            rows, cont = [], False
            while j < len(lines) and (j < end if end is not None
                                      else lines[j].strip() and not FOOTER.match(lines[j].strip())):
                # with footers off, the next table can follow right away
                # (as normalize_md.py handles): a header line or a \\x record
                if not cont and (RECORD.match(lines[j]) or (
                        j + 1 < len(lines) and lines[j].strip() and SEP_ALIGNED.match(lines[j + 1].strip()))):
                    break
                cells, more = cut(lines[j], bounds)
                if cont and rows:  # the rest of a multi-line value
                    rows[-1] = [p + ("\n" + c if c else "") for p, c in zip(rows[-1], cells)]
                else:
                    rows.append(cells)
                cont = more
                j += 1
            yield heads, rows
            i = j
        elif RECORD.match(lines[i]):
            recs, cur = [], {}
            while i < len(lines) and (RECORD.match(lines[i]) or "|" in lines[i]):
                # an aligned table right after (footers off): leave its header
                # for the outer loop
                if (not RECORD.match(lines[i]) and i + 1 < len(lines)
                        and SEP_ALIGNED.match(lines[i + 1].strip())):
                    break
                if RECORD.match(lines[i]):
                    if cur:
                        recs.append(cur)
                    cur = {}
                else:
                    k, _, val = lines[i].partition("|")
                    cur.setdefault(k.strip(), val.strip())
                i += 1
            if cur:
                recs.append(cur)
            heads = list(dict.fromkeys(k for r in recs for k in r))
            yield heads, [[r.get(h, "") for h in heads] for r in recs]
        else:
            i += 1


def empty_columns(path):
    """'empty column "X" (all N rows)' for each column of a table with 2 or
    more rows that is empty in all of them: a value the script never gets."""
    if not path.exists():
        return []
    out = []
    for heads, rows in tables(path.read_text(errors="replace").split("\n")):
        if len(rows) < 2:
            continue
        for c, h in enumerate(heads):
            if h and all(r[c] in EMPTY for r in rows if c < len(r)):
                out.append(f'empty column "{h}" (all {len(rows)} rows)')
    return out


def needs_lines(path):
    if not path.exists():
        return []
    return [f"as superuser: {l.strip()}" for l in path.open(errors="replace") if l.startswith("- Needs")]


def problems(csv_path):
    """Yield (version, script, [messages]) for every failed run in one results.csv."""
    d = csv_path.parent
    for r in csv.DictReader(csv_path.open(newline="")):
        v, s = r["version"], r["script"]
        if s == "END":
            continue
        rc, err, fat, to = (int(r[k] or 0) for k in ("rc", "errors", "fatal", "timeout"))
        if s == "REPORTS":
            if rc == 0 and err == 0 and fat == 0:
                continue
            log = d / "reports.log"
            msgs = [l.strip() for l in log.open(errors="replace")
                    if "ERROR:" in l or "FATAL:" in l or "FAIL" in l] if log.exists() else []
            for md in sorted(d.glob("reports/*/*.md")):
                msgs += error_lines(md)
        else:
            plain = not s.startswith(("FIXTURE", "CONNECT", "LOWPRIV"))
            empty = empty_columns(d / f"{s}.out") if plain else []
            # "- Needs ..." in a superuser run, on the fixture that installs every
            # extension: a privilege or extension check that is wrong
            needs = needs_lines(d / f"{s}.out") if plain and "@" not in s and int(r["needs"] or 0) else []
            if not (err or fat or to or rc or empty or needs):
                continue
            msgs = error_lines(d / f"{s}.out") + empty + needs
        if to:
            msgs.append("TIMEOUT")
        elif rc and msgs:
            # a known error line must not hide a failed psql (lost connection...)
            msgs.append(f"exit code {rc}")
        if not msgs:
            out = d / ("fixture.log" if s.startswith("FIXTURE") else f"{s}.out")
            lines = [l.strip() for l in out.open(errors="replace") if l.strip()] if out.exists() else []
            # the first line that looks like the cause, else the last one
            last = [l for l in lines if re.search(r"error|fail|cannot|not found|no such", l, re.I)][:1] or lines[-1:]
            msgs = [f"exit code {rc}" + (f": {PREFIX.sub('', last[0])}" if last else "")]
        yield v, s, list(dict.fromkeys(msgs))


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("paths", nargs="+", type=Path)
    ap.add_argument("--known", type=Path, default=Path(__file__).absolute().parent / "known_failures.csv")
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--versions", default="",
                    help="versions that must have results, e.g. '82 83 10 18' or 'all'")
    a = ap.parse_args(argv)
    try:
        expected = (set(ORDER[:-1]) if a.versions.strip() == "all"
                    else expand_versions(a.versions) if a.versions.strip() else set())
    except ValueError as e:
        print(f"check_battery: --versions: {e}", file=sys.stderr)
        return 2
    try:
        known = read_known(a.known)
    except (OSError, ValueError, re.error) as e:
        print(f"check_battery: {e}", file=sys.stderr)
        return 2
    csvs = []
    for p in a.paths:
        if not p.exists():  # a typo or a version that never ran: never skip it silently
            print(f"check_battery: {p} does not exist", file=sys.stderr)
            return 2
        found = [p] if p.is_file() else sorted(p.rglob("results.csv"))
        if not found:
            print(f"check_battery: no results.csv in {p}", file=sys.stderr)
            return 2
        csvs += found
    if not csvs:
        print("check_battery: no results.csv found", file=sys.stderr)
        return 2

    runs, versions, ran = 0, set(), set()
    new = defaultdict(lambda: defaultdict(list))  # script -> first message -> versions
    n_known = 0
    for c in csvs:
        rows, ended, cv = 0, False, c.parent.name
        for r in csv.DictReader(c.open(newline="")):
            if r["script"] == "END":
                ended = True
                continue
            rows += 1
            cv = r["version"]
            versions.add(r["version"])
            ran.add((r["script"], r["version"]))
        runs += rows
        # an interrupted or never-started battery is not a clean one
        if not rows:
            new["(no runs)"][f"no runs recorded in {c}"].append(cv)
        elif not ended:
            new["(incomplete)"][f"run interrupted: no END row in {c}"].append(cv)
        for v, s, msgs in problems(c):
            # known when every message is covered by an entry for this script and
            # version (one entry may cover an error, another an empty column)
            # an entry for "x" also covers "x@low" (the unprivileged pass); one for
            # "x@low" only that pass
            mine = [e for e in known if e["script"] in (s, s.split("@")[0])
                    and (e["versions"] is None or v in e["versions"])]
            bad = []
            for m in msgs:
                hits = [e for e in mine if e["pattern"].search(m)]
                for e in hits:
                    e["hits"] += 1
                if not hits:
                    bad.append(m)
            if not bad:
                n_known += 1
            else:
                new[s][f"{bad[0][:160]}" + (f" (+{len(bad) - 1} more)" if len(bad) > 1 else "")].append(v)

    # stale: never matched although its script ran on one of its versions
    # a version asked for that left no results at all (its cluster never came up...)
    for v in sorted(expected - versions, key=vkey):
        new["(missing)"]["no results for this version: it did not run"].append(v)

    stale = [e for e in known if e["hits"] == 0
             and any(sc == e["script"] and (e["versions"] is None or v in e["versions"]) for sc, v in ran)]
    vs = sorted(versions, key=vkey)
    print(f"{runs} runs on {len(vs)} version(s) ({' '.join(vs)}): "
          f"{sum(len(x) for m in new.values() for x in m.values())} new problem(s), {n_known} known")
    for s in sorted(new):
        print(f"\nNEW {s}")
        for m, vv in new[s].items():
            print(f"   [{','.join(sorted(vv, key=vkey))}] {m}")
    for e in stale:
        print(f"\n{'STALE' if a.strict else 'note'}: known failure not seen any more: "
              f"{e['script']} [{e['spec']}] {e['pattern'].pattern}")
    return 1 if new or (a.strict and stale) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
