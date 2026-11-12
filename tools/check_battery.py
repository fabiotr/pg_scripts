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
  ./tools/check_battery.py [--known FILE] [--strict] PATH [PATH ...]
  PATH: a results.csv, or a directory searched recursively for results.csv
  (e.g. one run_battery.sh output directory per version under one parent).
  --known   known failures file (default: known_failures.csv next to this script)
  --strict  also fail when a known failure no longer happens (stale entry)

Exit code: 0 when every problem is known, 1 when there is a new problem (or a
stale entry with --strict), 2 when the input can't be read.

known_failures.csv columns: script,versions,pattern,reason
  versions: space-separated labels (82 83 ... 96 10 ... 18), ranges in that
            order (82-92) or "all"
  pattern:  Python regular expression searched in each error line (with the
            "psql:file:line: " prefix removed); a run is known only when all
            its error lines match. Lines starting with # are comments.
"""
import argparse
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

ORDER = ["82", "83", "84", "90", "91", "92", "93", "94", "95", "96",
         "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"]
PREFIX = re.compile(r"^psql:[^:]+:\d+: ")


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
            if "ERROR:" in l or "FATAL:" in l]


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
            if not (err or fat or to or rc):
                continue
            msgs = error_lines(d / f"{s}.out")
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
    a = ap.parse_args(argv)
    try:
        known = read_known(a.known)
    except (OSError, ValueError, re.error) as e:
        print(f"check_battery: {e}", file=sys.stderr)
        return 2
    csvs = []
    for p in a.paths:
        csvs += [p] if p.is_file() else sorted(p.rglob("results.csv"))
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
            hit = next((e for e in known if e["script"] == s
                        and (e["versions"] is None or v in e["versions"])
                        and all(e["pattern"].search(m) for m in msgs)), None)
            if hit:
                hit["hits"] += 1
                n_known += 1
            else:
                bad = [m for m in msgs if not any(
                    e["pattern"].search(m) for e in known if e["script"] == s)] or msgs
                new[s][f"{bad[0][:160]}" + (f" (+{len(bad) - 1} more)" if len(bad) > 1 else "")].append(v)

    # stale: never matched although its script ran on one of its versions
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
