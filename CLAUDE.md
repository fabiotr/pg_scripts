# pg_scripts — PostgreSQL DBA Essentials

Public library of psql scripts for PostgreSQL DBAs, supporting **PG 8.2 → 18** (PG 19 in progress, see `TODO.md`).
Everything is written in English (code, comments, column aliases, commit messages, docs).

## Layout

- `sql/` — all SQL scripts (flat, no subfolders). Run via psql; they rely on psql meta-commands.
- `reports/` — full Markdown reports (`report_cluster.sql`, `report_database.sql`), generator (`generate_reports.sh` / `.ps1`), `normalize_md.py`, `report.conf.example` (copy to the git-ignored `report.conf`).
- `linux_bash/` — bash scripts. `windows_power_shell/` — PowerShell ports **mirroring the same file names** (`.sh` → `.ps1`).
- `tools/` — repository maintenance scripts (not shipped to users, no PowerShell twin). `tools/check_dispatchers.py` validates the dispatcher rules below; `tools/check_sql_style.py` validates the SQL style rules (keyword and identifier case, ASCII identifiers, ambiguous strings). Both are documented in `tools/README.md`; keep it in step when a rule changes.
- `psqlrc` — recommended `~/.psqlrc` (does `\cd $HOME/pg_scripts/sql`).
- `README.md` — the script catalog. `TODO.md` — roadmap (done items are ~~struck through~~ with a "(see `file.sql`)" note).

## SQL scripts: the dispatcher pattern

Every user-facing script is a **dispatcher** `<name>.sql` plus one or more **versioned implementations** `<name>_<VV>up.sql`.

Dispatcher template (copy exactly, only change the branches):

```sql
\ir variables.sql

\if :svp_pg_17
  \ir <name>_17up.sql
\elif :svp_pg_13
  \ir <name>_13up.sql
\elif :svp_pg_84
  \ir <name>_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
```

Rules:
- Branches go **from newest to oldest** version. Each `\ir` must point to the file matching its own `\if` (e.g. `svp_pg_16` → `_16up.sql`).
- **Every** `_<VV>up.sql` file must be reachable from some branch. Past bugs: a PG16 branch calling `_17up.sql`; `_82up`/`_83up`/`_96up` files with no branch; a `svp_pg_13` branch placed before `svp_pg_18`, making the PG18 file dead code.
- Run `./tools/check_dispatchers.py` after adding, renaming or editing any SQL file. It must print `All dispatchers OK`.
- Always include with `\ir` (relative to the file), never `\i`. `\i` only works when the cwd is `sql/`.
- The "not supported" message is exactly `\qecho - Not supported on version :svp_server_version` (capital N).
- Add `\x on` / `\x off` around the branches when the output is a single wide row (e.g. `checkpoints.sql`).
- The versioned file holds **only the query**: no `\ir variables.sql`, no `\timing`, no `QUIET` handling.
- Only create a new `_<VV>up.sql` when the catalog/view actually changed in that version. Don't duplicate identical queries.

### Version suffix

- `VV` = major version without the dot: `82`, `84`, `90`, `91`, `92`, `93`, `94`, `95`, `96`, `10`, `11` … `18`.
- `_<VV>up` = "this version and newer". `_<VV>-` = "up to and including this version" (only `tables_with_oid_11-.sql`; use it for features that were removed).
- A script supporting a single version range still gets a dispatcher (e.g. `connections_io.sql` → `connections_io_18up.sql`).
- Scripts that don't depend on the version (e.g. `*_drop.sql`, `*_adjust.sql`, `pgbouncer_fdw.sql`) may be a single file with no suffix.

### `variables.sql`

Sets every `svp_*` psql variable via `\gset svp_`. Use these instead of querying the version yourself:
- `svp_pg_82` … `svp_pg_18`, `svp_under_pg_12`, `svp_server_version`
- environment: `svp_rol_super`, `svp_not_standby`, `svp_recovery`, `svp_master`, `svp_not_dbaas`, `svp_not_rds`, `svp_not_gcp`, `svp_not_aurora`
- features: `svp_ext` / `svp_not_ext` (pg_stat_statements), `svp_lib`, `svp_track_io`, `svp_plan`, `svp_jit`, `svp_logging_collector`, `svp_publication`, `svp_subscription`, `svp_logical_replication_slot`
- privileges: `svp_ls_tmpdir`, `svp_ls_waldir`, `svp_ls_logdir`, `svp_pgstatindex`, `svp_pgstatginindex`, `svp_pgstathashindex`, `svp_pgstattuple_approx`, `svp_shmem_allocations`: TRUE when the function/view exists and the user can use it. A script that needs one checks it in the dispatcher and prints `\qecho - Needs <role> (or EXECUTE on <function>())` instead of failing with permission denied. Add a flag here for any new function or view that PUBLIC can't use.

To support a new major version: add `svp_pg_<VV>` (`>= VV0000`) to `variables.sql` first.
If you need a new environment flag, add it there and give it a fallback `\set` in the `\else` branch for older versions.

## File naming

`snake_case`, `<subject>_<detail>[_<qualifier>].sql`. The prefix defines the family, so reuse an existing one:

| Prefix | Scope |
|---|---|
| `statements_*` | pg_stat_statements (database); `statements_cluster_*` = whole cluster |
| `tables_*`, `index_*`, `sequence_*`, `functions_*`, `trigger_*`, `schemas_*` | objects |
| `connections_*` | pg_stat_activity (`_by_<dimension>` for groupings) |
| `kill_*` | terminate backends: `kill_<state>_<condition>_greater_<N>_<unit>` |
| `conf_*` | pg_settings groups (`conf_logs`, `conf_resource`…) |
| `autovacuum_*`, `vacuum_*`, `progress_*` | maintenance / progress views |
| `replication_*`, `publication*`, `subscription_*`, `wal_*` | replication |
| `io_*`, `checkpoints`, `bgwriter`, `stats_*`, `database_*` | cluster stats |
| `user_*`, `role_*`, `security_*`, `revoke_*` | security |

Common suffixes: `_top5`, `_detail`, `_report`, `_plus` (more columns), `_adjust` (generates ALTER statements), `_drop` / `_create` (generates DDL), `_dup`, `_invalid`, `_missing`.

## SQL style

Match the existing code (it differs from what `CONTRIBUTING.md` says about lowercase):
- **Uppercase** SQL keywords (`SELECT`, `FROM`, `WHERE`, `CASE WHEN`), including the function-like reserved words `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_USER`, and the second word of `PRIMARY KEY`, `FOREIGN KEY`, `ORDER BY`, `GROUP BY`.
- **Lowercase** unquoted identifiers: table, column, alias, schema and function names, PL/pgSQL and psql variables you define, and `EXTRACT` fields: `sum(x)`, `round(...)`, `now()`, `count(*)`, `current_schema()`, `t.relname`, `EXTRACT(epoch FROM ...)`, `SET client_min_messages TO warning`. PostgreSQL folds unquoted identifiers to lowercase anyway, so this is only style. psql's own variables stay as psql defines them (`:DBNAME`).
- **ASCII-only** unquoted identifiers and dollar-quote tags (`$body$`, not `$café$`): PostgreSQL case-folds non-ASCII letters differently depending on the server encoding. Non-ASCII text is fine inside strings, quoted identifiers (`"σ"`), comments and `\qecho`.
- Case inside strings is never changed: it can be meaningful, e.g. `to_char` patterns (`'Month'` gives `September`, `'MONTH'` gives `SEPTEMBER`).
- Inside function bodies and `DO` blocks in `LANGUAGE sql`/`plpgsql` (`CREATE FUNCTION ... AS $$ ... $$`, `DO $$ ... $$`) the same rules apply, since the body is code: PL/pgSQL reserved keywords (`DECLARE`, `BEGIN`, `IF`, `LOOP`, `STRICT`, ...) are uppercase, and its special variables (`FOUND`, `SQLSTATE`, `SQLERRM`, `NEW`, `OLD`, `TG_OP`, ...) are **always uppercase**. Other `$$ ... $$` literals (e.g. generated `ALTER SYSTEM` text) are strings.
- `./tools/check_sql_style.py` enforces these rules; `--fix` fixes the case of keywords, identifiers and special variables (non-ASCII identifiers have to be renamed by hand). Keywords PostgreSQL doesn't reserve (`coalesce`, `nullif`, `text`, `numeric`, `year`, `name`, `raise`, `notice`, ...) and syntax words it reads as identifiers (`LOGIN`, `NOLOGIN`, `USAGE`, `CONNECT`) can't be told apart from identifiers without a full parser, so their case is free. Types that aren't keywords (`record`, `jsonb`, `regclass`) are identifiers: lowercase.
- Quotes inside strings are doubled (`'can''t'`), which works from 8.2 to 18. **No backslash in a plain `'...'` string**: its meaning depends on `standard_conforming_strings` (off by default up to 9.0, on since 9.1), e.g. `'\s+'` is `s+` with it off, so `regexp_split_to_array(x, '\s+')` splits on the letter s. Use an explicit `E'\\s+'`, which is the same on every version. A backslash right before a quote (`'can\'t'`, `'C:\'`) is worse: where the string ends changes. `check_sql_style.py` reports both, and `--fix` rewrites the first kind as `E'...'`.
- Quoted, human-readable column aliases, left-padded/formatted for psql output: `AS "Avg size"`, `lpad(to_char(x,'FM9G990D0'),8)`, `pg_size_pretty(...)`.
- Protect divisions with `nullif(..., 0)`. Normalize rates per day using `stats_reset` (see `checkpoints_17up.sql`).
- Meaningful table aliases on joins. No hardcoded schemas besides `pg_catalog`.
- Prefer `pg_options_to_table(reloptions)` over `unnest(reloptions)` parsing.
- Scripts must be **read-only** unless the name says otherwise (`kill_*`, `*_drop`, `*_adjust`, `revoke_*`). Destructive/generator scripts should print or generate commands rather than silently running DDL.
- Filter template databases (`datistemplate`) and DBaaS admin databases (`rdsadmin`, `cloudsqladmin`) in cluster-wide queries.

## Shell scripts

- Shebang `#!/usr/bin/env bash`, then a header comment block: what it does, requirements, important notes, usage. Then `set -euo pipefail`.
- Every `linux_bash/*.sh` has a PowerShell twin in `windows_power_shell/*.ps1` (same for `reports/generate_reports`). **Change both** in the same PR.
- Porting gotcha: variables set inside a bash subshell/pipe vs. PowerShell function scope. Check scope when porting loops.
- Configuration comes from flags / env vars. No environment-specific defaults (no hostnames, company names, credentials).

## When adding or changing a script, also update

1. `README.md` catalog: add a row to the right category table, keeping alphabetical order:
   `| Cluster|Database | \`name.sql\` | PG >= X.Y | Description | [\`catalog_view\`](link to postgresql.org docs) |`
2. `TODO.md`: strike through the done item and add "(see `name.sql`)".
3. `reports/report_*.sql`, if the script belongs in the full reports.

## Testing

- `./tools/check_dispatchers.py` (static checks: `\ir`, include targets, branch/file versions, branch order, unreachable files, message casing).
- `./tools/check_sql_style.py` (keyword and identifier case, non-ASCII identifiers and dollar-quote tags, plain strings that depend on `standard_conforming_strings`; strings, comments and quoted identifiers are never checked). Tests for both checks: `python3 -m unittest discover -s tools -p 'test_*.py'` (add a case to `tools/test_check_dispatchers.py` or `tools/test_check_sql_style.py` when changing a check). Both checks and the tests run in CI on every PR.
- Run against **every supported major version** that has its own branch (Docker `postgres:<VV>` images are the easiest way), plus at least one DBaaS if the script checks `svp_not_rds`/`svp_not_aurora`.
- Run with `psql -X` so a local `~/.psqlrc` doesn't change the output. `\timing` in psqlrc prints "Timing is on", which pollutes reports.
- Minimum check: `psql -X -f sql/<name>.sql` on the oldest and the newest supported version.

## Git

- Small, focused commits. Imperative messages describing the file(s): `Add foreign_servers.sql: ...`, `Fix collations.sql: PG16 branch was calling ...`, `Update README: ...`.
- Work on a branch and open a PR (`CONTRIBUTING.md`). Don't push directly to `main`.
