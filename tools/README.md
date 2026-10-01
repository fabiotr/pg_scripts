# 🧰 Maintenance Tools

Checks that keep the repository consistent. They are for contributors: none of them connects to a database, and none of them is part of the script library. CI runs all of them on every pull request (`.github/workflows/check-dispatchers.yml`).

| File                         | What it does                                                    |
| :---                         | :---                                                            |
| `check_dispatchers.py`       | Checks the version dispatchers in `sql/` and the includes in `reports/`. |
| `check_sql_style.py`         | Checks (and with `--fix`, fixes) the SQL style of `sql/` and `reports/`. |
| `test_check_dispatchers.py`  | Tests for `check_dispatchers.py`.                               |
| `test_check_sql_style.py`    | Tests for `check_sql_style.py`.                                 |

Requirements: Python 3.9+, standard library only. No other packages, and no database.

## Quick start

From the repository root:

```bash
./tools/check_dispatchers.py        # must print "All dispatchers OK"
./tools/check_sql_style.py          # must print "All SQL style checks OK"
./tools/check_sql_style.py --fix    # fixes what it can, see below
python3 -m unittest discover -s tools -p 'test_*.py'   # tests for both checks
```

Problems are printed as `file:line: message`. Both checks exit with 0 when everything is fine, 1 when a problem is found, and 2 when they can't run (not the pg_scripts repository, no SQL files).

## `check_dispatchers.py`

A script that depends on the server version is a dispatcher: `<name>.sql` picks one implementation with the `svp_pg_VV` variables set by `sql/variables.sql` (see [CLAUDE.md](../CLAUDE.md)):

```sql
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
