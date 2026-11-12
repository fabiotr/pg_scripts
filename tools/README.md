# 🧰 Maintenance Tools

Tools for contributors, not part of the script library. The static checks keep the repository consistent without a database, and CI runs them on every pull request (`.github/workflows/check-dispatchers.yml`). The regression battery runs every script on a real server (see [Regression battery](#regression-battery)); it isn't in CI yet.

| File                         | What it does                                                    |
| :---                         | :---                                                            |
| `check_dispatchers.py`       | Checks the version dispatchers in `sql/` and the includes in `reports/`. |
| `check_sql_style.py`         | Checks (and with `--fix`, fixes) the SQL style of `sql/` and `reports/`. |
| `test_check_dispatchers.py`  | Tests for `check_dispatchers.py`.                               |
| `test_check_sql_style.py`    | Tests for `check_sql_style.py`.                                 |
| `fixture.sh`                 | Builds a test database with data and odd objects, plus background sessions. |
| `run_battery.sh`             | Runs every entry script and both reports on one server, records errors. |
| `check_battery.py`           | Compares battery results with `known_failures.csv`.             |
| `known_failures.csv`         | Errors the battery expects (test environment, not bugs).       |
| `check_report_md.py`         | Checks the Markdown reports: psql footers or feedback leaking in, broken tables, unclosed code blocks. |
| `test_check_battery.py`      | Tests for `check_battery.py`.                                   |
| `test_check_report_md.py`    | Tests for `check_report_md.py`.                                 |

Requirements for the static checks: Python 3.9+, standard library only. No other packages, and no database. The battery also needs bash 4+, psql 12+ (any server from 8.2; the scripts themselves need psql 10+), GNU `timeout`, a `stdbuf` (on macOS Homebrew's `coreutils` gives both, unprefixed or as `gtimeout`/`gstdbuf`; `run_battery.sh` links the prefixed ones under the plain names for `generate_reports.sh`, and macOS's own `stdbuf` works too) and a throwaway PostgreSQL server.

## Quick start

From the repository root:

```bash
./tools/check_dispatchers.py        # must print "All dispatchers OK"
./tools/check_sql_style.py          # must print "All SQL style checks OK"
./tools/check_sql_style.py --fix    # fixes what it can, see below
python3 -m unittest discover -s tools -p 'test_*.py'   # tests for the checks
```

Problems are printed as `file:line: message`. Both checks exit with 0 when everything is fine, 1 when a problem is found, and 2 when they can't run (not the pg_scripts repository, no SQL files).

## `check_dispatchers.py`

A script that depends on the server version is a dispatcher: `<name>.sql` loads `variables.sql`, which sets the `svp_pg_VV` variables, and picks one implementation with them (see [CLAUDE.md](../CLAUDE.md)):

```sql
\ir variables.sql

\if :svp_pg_16
    \ir <name>_16up.sql
\elif :svp_pg_10
    \ir <name>_10up.sql
\else
    \qecho - Not supported on version :svp_server_version
\endif
```

The check reports:

- `\i` in `sql/` (use `\ir`, which resolves relative to the file; `\i` only works when the current directory is `sql/`). `reports/` may use `\i`.
- An `\i` / `\ir` target that doesn't exist. Targets built from psql variables (`\ir :sql_dir/...`) can't be checked and are skipped.
- A branch `\if :svp_pg_VV` / `\elif :svp_pg_VV` that includes a `<name>_WWup.sql` with another version.
- `svp_pg_*` branches of one `\if` chain that don't go from newest to oldest version (`96` is 9.6 and `82` is 8.2, both older than `10`).
- A versioned file (`<name>_VVup.sql`, `<name>_VV-.sql`) that no script includes, i.e. an unreachable implementation.
- `\qecho - not supported on version` with a lowercase `n`.

psql commands are found with `check_sql_style.py`'s tokenizer, so a `\` line inside a comment, a string or a `$$` body isn't taken as a command.

```bash
./tools/check_dispatchers.py [repo_dir]
```

`repo_dir` defaults to the parent directory of `tools/`, or to the git top level when the script is run through a symlink (as a hook).

## `check_sql_style.py`

| Rule | Example | `--fix` |
| :--- | :--- | :--- |
| Reserved keywords are uppercase. "Reserved" is PostgreSQL's own list (`pg_get_keywords()` categories R and T). The second word of `PRIMARY KEY`, `FOREIGN KEY`, `ORDER BY` and `GROUP BY` follows the first. | `select` → `SELECT` | yes |
| Unquoted identifiers are lowercase: tables, columns, aliases, schemas, functions, PL/pgSQL variables, `EXTRACT` fields such as `epoch`, types that aren't keywords (`record`, `jsonb`). | `NOW()` → `now()` | yes |
| Unquoted identifiers and dollar-quote tags are ASCII-only. PostgreSQL case-folds non-ASCII letters depending on the server encoding. | `$café$` | no, rename by hand |
| Function bodies and `DO` blocks in `sql` / `plpgsql` are checked as code: PL/pgSQL reserved keywords (`DECLARE`, `BEGIN`, `IF`, ...) and special variables (`FOUND`, `SQLSTATE`, `SQLERRM`, `NEW`, `OLD`, `TG_*`) are uppercase. | `found` → `FOUND` | yes |
| No backslash in a plain `'...'` string: with `standard_conforming_strings` off (the default up to 9.0) `'\s+'` means `s+`. | `'\s+'` → `E'\\s+'` | yes |
| A backslash right before one of the quotes of a plain string is ambiguous, since even where the string ends depends on that setting. | `'a\'` | no, rewrite with `''` or `E'...'`; the rest of the file isn't checked |

What the check never looks at: the case of unreserved keywords (`coalesce`, `text`, `name`, `raise`, `notice`, ...), which can't be told apart from identifiers without a full parser; role options and privileges (`LOGIN`, `USAGE`, ...); and the text inside strings, `$$` literals that aren't function bodies, quoted identifiers, comments, psql `\` lines and psql variables (`:name`, `:{?name}`). So `to_char(x, 'Month')` and `'MONTH'` stay as written.

```bash
./tools/check_sql_style.py [--fix] [--root DIR] [PATH_OR_GLOB ...]
./tools/check_sql_style.py [--fix] REPO_DIR
```

The files default to `sql/*.sql` and `reports/*.sql` in pg_scripts, and to every `**/*.sql` in another repository. A copy of this script runs in storyblok/database-scripts. Changes are made here first and then copied there, so the two files stay byte-identical.

## Tests

```bash
python3 -m unittest discover -s tools -p 'test_*.py' -v
```

- `test_check_dispatchers.py` runs each rule against a throwaway repository, plus a clean repository, a directory that isn't the repository, and the symlinked pre-commit hook. `CHECK_DISPATCHERS=/path/to/copy.py` points the tests at another copy of the script, for example a deliberately broken one, to confirm that some test fails.
- `test_check_sql_style.py` covers the tokenizer (strings, nested comments, dollar quotes, numbers, psql variables and `\` lines), each rule, `--fix`, and the linear-time cases (many or unterminated dollar quotes).
- `test_check_battery.py` builds fake battery output: clean runs, known and new errors, a second error in a script with a known one, version ranges, timeouts, exit codes, report failures, stale entries, and a check that `known_failures.csv` itself parses. `CHECK_BATTERY` points it at another copy of the script.
- `test_check_report_md.py` covers each kind of problem, GFM's optional end pipes, escaped pipes and backslashes, code blocks (left alone) and a file that can't be read. `CHECK_REPORT_MD` points it at another copy of the script.

When you change a check, add a case that fails without your change.

## Running the checks before every commit

```bash
printf '#!/bin/sh\n./tools/check_dispatchers.py && ./tools/check_sql_style.py\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Or only the dispatcher check, as a symlink:

```bash
ln -s ../../tools/check_dispatchers.py .git/hooks/pre-commit
```

## Regression battery

Static checks can't tell whether a query still works on 8.2 or on 18, or on a database with real data. The battery runs every entry script of `sql/` (the dispatchers and the unversioned files) and both reports on a live server, and `check_battery.py` fails when an error shows up that isn't in `known_failures.csv`.

> [!WARNING]
> Throwaway test clusters only, never a server with anything you want to keep. The battery runs everything, including `kill_*` (terminates sessions), `stats_reset_all` (resets statistics), `pgbouncer_fdw` (creates a schema) and the `\gexec` scripts. The fixture drops and recreates its own database and creates the roles `fix_reader` and `fix_writer`.

### `fixture.sh`

Without data many scripts return nothing and their logic is never exercised: the `pgstatindex()` call on an invalid index and `bt_index_check()` on a partitioned index (fixed in #90) only failed once there were such indexes, and a division by `reltuples` only once a table had 0 rows analyzed. `fixture.sh` builds a database (`fixdb` by default, about 10 s and 170 MB) with, on each version that supports them: bloated tables, large TOAST values, per-table `reloptions` (and `pg_autovacuum` rows on 8.2/8.3), inheritance and two-level declarative partitions, partitioned indexes, materialized views (one never populated), unlogged tables (one empty and analyzed, as crash recovery leaves them), sequences near their limit, every index type, a duplicate, an invalid and an unused index, a foreign key without an index, functions, triggers, domains, composite, enum and range types, collations, extended statistics, `WITH OIDS` tables, and a schema outside `search_path` whose names need quoting. It loads `pg_stat_statements`, `pgstattuple` and `pg_buffercache`. The full list is in the script header.

```bash
tools/fixture.sh            # build (skipped when already at the current version) + load
tools/fixture.sh --rebuild  # drop and build again
tools/fixture.sh load       # workload again: pg_stat_statements, function calls, scans, temp files
tools/fixture.sh start      # background sessions: idle in transaction, a blocker and the
                            # session it blocks, a long active query, a COPY in progress
                            # into an empty analyzed table; respawned when killed
tools/fixture.sh stop
tools/fixture.sh status
```

It connects with the usual libpq variables (`PGHOST`, `PGPORT`, `PGUSER`, `PGSERVICE`) as a superuser, and uses plain SQL that every version parses (no `IF NOT EXISTS`, `ON CONFLICT` or `DO`). On servers before 9.1, which have no `CREATE EXTENSION`, the contrib scripts come from `FIXTURE_CONTRIB_DIR` or `` `pg_config --sharedir`/contrib `` (`PG_CONFIG` picks the `pg_config`). It refuses to drop a database it didn't create. It warns, without failing, when a setting some scripts need is off (`track_counts`, `track_activities`, `track_functions`, `track_io_timing`, `pg_stat_statements` in `shared_preload_libraries`; 8.2 has older names): those scripts would come out empty and pass without being tested.

When a bug depends on data, add the object that shows it to the fixture and bump `FIXTURE_VERSION`, so the battery catches it from then on.

### `run_battery.sh` and `check_battery.py`

```bash
PGSERVICE=pg16 tools/run_battery.sh --fixture -o /tmp/battery/16
PGSERVICE=pg10 tools/run_battery.sh --fixture -o /tmp/battery/10
tools/check_battery.py --versions "10 16" /tmp/battery   # every results.csv below it
```

`run_battery.sh` runs each script with `psql -X -f`, stdin closed and a timeout (`-t`, 120 s), from `sql/`, on the fixture database with `--fixture` (or `-d`). `--fixture` rebuilds the database every time, since the battery changes it (`pgbouncer_fdw` creates a schema, `stats_reset_all` zeroes counters), so every run starts from the same state; `--reuse-fixture` keeps it when it is current, to iterate faster on one script. Scripts run in name order except the statistics resets (`stats_reset_*`), which run last so the scripts that read activity counters still see the fixture's workload. A fixture that fails or refuses the database stops the run: nothing is run on a database it didn't build. It writes `results.csv` (version, script, exit code, lines, `ERROR` / `FATAL` / timeout counts, "Not supported" and "Needs" messages, checksum) and one `<script>.out` per script. The two report SQL files also run directly, stderr included (`report_cluster.out`, `report_database.out`): `generate_reports.sh` keeps psql's stderr only when a report fails, so an error inside a section would be lost. `generate_reports.sh` itself runs too (row `REPORTS`, Markdown under `reports/`, `reports.log`) when there is a `pg_service.conf` entry (`-S` or `PGSERVICE`), with an empty config of its own (`-c`), so a local `reports/report.conf` can't send the reports to another database. Before it, only the date folders of an earlier run are removed from `reports/`, never the directory itself. `-s "name ..."` limits the run to some scripts and `-R` skips the reports. `check_report_md.py` then checks that Markdown (row `report_md`): no psql row-count footer (`(12 rows)`, a script left `\pset footer on`), no psql feedback (`Time: 0.3 ms`, `Timing is on.`, `Expanded display is ...`), no table row with more cells than its header (GFM drops them) or a short one written with its leading `|`, and no unclosed code block. It counts cells as GFM does, with optional end pipes. It also runs on its own: `tools/check_report_md.py reports/*.md`.

Two more passes check the rules in `CLAUDE.md`:

- **Read-only.** Every script whose name doesn't declare a write (`kill_*`, `*_drop`, `*_adjust`, `revoke_*`, `stats_reset*`, `pgbouncer_fdw`) runs with `default_transaction_read_only = on`, so a hidden write (a `nextval()`, a `CREATE EXTENSION`) is an error.
- **Unprivileged.** `--lowpriv ROLE` runs those scripts and the report SQL again as a login without superuser (rows `<name>@low`); the fixture creates `fix_monitor`, with `pg_monitor` from 10 on, as on DBaaS. A script that lacks a privilege must print `- Needs ...`, not fail. `~/pgtest`-style orchestration passes `--lowpriv fix_monitor`.

`check_battery.py` reports every run with an `ERROR` or `FATAL` line, a psql client error (`psql:<file>:<line>: error: ...`, e.g. an `\ir` to a missing file, after which psql still exits with 0), a timeout, a failed psql, or a column that is empty in every row of a table with 2+ rows (`empty column "X" (all N rows)`: a value the script never gets, the kind of bug that runs without an error), grouped by script and message with the versions where it happened, and exits with 1 when one of them isn't in `known_failures.csv`. An entry there names the script (an entry for `x` also covers `x@low`; one for `x@low` only the unprivileged pass), the versions (`all`, `82-92`, `10 11`) and a regular expression; a run is known when **each** of its messages is matched by an entry, so a new error in a script with a known one is still reported. Besides the environment errors, the file lists the columns that are legitimately empty (nothing of that kind in the fixture, autovacuum not running, a value hidden from a non-superuser before 10), each with its reason. An entry that no longer matches anything is printed as a note (`--strict` makes it fail), so it can be removed. `--versions` lists the versions that must have results (`82 83 10-18`, `all`): one without any, e.g. a cluster that never came up, is a new problem, and a path that doesn't exist stops the check. A `results.csv` with no runs, or without the `END` row `run_battery.sh` writes last, is reported too: an interrupted battery is not a clean one. So is a fixture load that fails before the reports (row `FIXTURE_LOAD`).

```
3914 runs on 19 version(s) (82 83 ... 17 18): 8 new problem(s), 57 known

NEW index_check_btree_integrity
   [11,12,13,14,15,16,17] ERROR:  only B-Tree indexes are supported as targets for verification
```

Docker images (`postgres:<VV>`) are the easiest way to get one server per version. Versions up to 9.2 use System V shared memory, which macOS limits to 4 MB in all, so only one of them can run at a time there.
