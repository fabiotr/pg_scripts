#!/usr/bin/env bash
# Data fixture for testing the pg_scripts library: builds a database (default
# "fixdb") with enough data and odd objects for the sql/ scripts and the
# reports to exercise their logic instead of running on an almost empty
# database, plus background sessions (idle in transaction, a lock wait, a long
# active query) and pg_stat_statements load. Used by tools/run_battery.sh.
#
# Requirements: bash 4+, psql 10+ in PATH (any server 8.2 -> 18), a superuser
# connection through the usual libpq variables (PGHOST, PGPORT, PGUSER,
# PGSERVICE...). Servers before 9.1 have no CREATE EXTENSION: the contrib SQL
# scripts are read from FIXTURE_CONTRIB_DIR (default: `pg_config --sharedir`/contrib,
# with PG_CONFIG for the pg_config of that server).
#
# Important: for THROWAWAY test clusters only. It drops and recreates its own
# database (never one it didn't create), creates the cluster-wide roles
# fix_reader and fix_writer, writes to pg_autovacuum (8.2/8.3) and pg_index
# (8.2), and the battery it is made for kills sessions and resets statistics.
#
# Every feature is created only on the versions that have it, with plain SQL
# those versions parse: no IF NOT EXISTS / ON CONFLICT / DO.
#
#   build     drop and recreate the database (stops the sessions first) unless
#             it already holds this FIXTURE_VERSION; --rebuild forces it
#   load      workload: pg_stat_statements entries, function calls, index and
#             sequential scans, temp files (re-runnable, e.g. after a stats reset)
#   start     background sessions: idle in transaction, a blocker and the
#             session it blocks, a long active query, a COPY in progress into
#             an empty analyzed table; a supervisor respawns any one a kill_*
#             script terminates
#   stop      stop the supervisor and its sessions
#   status    show the fixture sessions in pg_stat_activity
#   (none)    build + load
#
# What the database gets (version where it starts):
#   bloat     bloat_upd / bloat_del: mass UPDATE/DELETE, autovacuum off (8.4+
#             reloption, 8.2/8.3 a pg_autovacuum row), fillfactor
#   TOAST     toast_big: ~48 kB incompressible rows, STORAGE EXTERNAL, toast.*
#             reloptions (8.4+), half of them updated (dead TOAST)
#   reloptions per table: fillfactor, autovacuum_* (8.4+), toast.* (8.4+),
#             autovacuum_vacuum_insert_* (13+), parallel_workers (9.6+)
#   partitions inheritance children with CHECKs (all); declarative two-level
#             range -> list (10+), partitioned indexes, PK, default and hash
#             partitions (11+)
#   matviews  populated + one WITH NO DATA (9.3+); unlogged tables (9.1+), one
#             empty and analyzed (reltuples 0, as crash recovery leaves them)
#   sequences int serial near its limit, CYCLE, smallint AS (10+), identity (10+)
#   indexes   btree, partial, expression, multi-column, gist, gin (int[] all,
#             tsvector 8.3+, jsonb 9.4+), spgist (9.2+), brin (9.5+), hash (10+),
#             INCLUDE (11+), a duplicate pair, an INVALID one (failed CREATE
#             INDEX CONCURRENTLY), one never used, FK without index
#   other     functions (sql, plpgsql, overloads, SECURITY DEFINER), trigger,
#             view, domains, composite, enum (8.3+), range (9.2+) types,
#             collations (9.1+, ICU 10+ when available), extended stats (10+),
#             exclusion constraint (9.0+), WITH OIDS table (<= 11), never
#             analyzed table, large objects, publication (10+), role grants,
#             a schema outside search_path with mixed-case / spaced names
#   extensions pg_stat_statements (8.4+), pgstattuple, pg_buffercache
#   It takes about 10 s and 160-190 MB.
#
# Usage: tools/fixture.sh [build|load|start|stop|status] [--rebuild]
# Env:   FIXDB (database, default fixdb), FIXTURE_ADMIN_DB (database to connect
#        to for CREATE/DROP DATABASE, default postgres), FIXTURE_RUN_DIR
#        (supervisor pid/log/FIFOs, default $TMPDIR/pg_scripts_fixture),
#        FIXTURE_CONTRIB_DIR, PG_CONFIG
# Example: PGSERVICE=pg16 tools/fixture.sh && PGSERVICE=pg16 tools/fixture.sh start
set -euo pipefail

FIXTURE_VERSION=2
DB="${FIXDB:-fixdb}"
ADMIN="${FIXTURE_ADMIN_DB:-postgres}"
cmd=all; rebuild=0
for a in "$@"; do
  case "$a" in
    --rebuild) rebuild=1 ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    *) cmd=$a ;;
  esac
done

P() { psql -X -q "$@" </dev/null; }
die() { echo "fixture${v:+ pg$v}: $*" >&2; exit 1; }
# the name is used unquoted in SQL: only a plain lowercase identifier, so the
# database checked is the one dropped (FixDB would be checked as FixDB, dropped as fixdb)
[[ $DB =~ ^[a-z_][a-z0-9_]{0,62}$ ]] || die "FIXDB must be a lowercase identifier ([a-z_][a-z0-9_]*, up to 63 characters): $DB"
svn=$(P -d "$ADMIN" -Atc 'SHOW server_version_num' 2>/dev/null) \
  || die "cannot connect to database $ADMIN (set PGHOST/PGPORT/PGUSER or PGSERVICE)"
# n: 802 ... 906, 1000 ... 1800 (as the svp_pg_* flags); v: the file suffix label (82, 96, 10, 18)
if [[ $svn -ge 100000 ]]; then n=$(( svn / 10000 * 100 )); else n=$(( svn / 100 )); fi
if [[ $n -ge 1000 ]]; then v=$(( n / 100 )); else v=$(( n / 100 * 10 + n % 100 )); fi
[[ $(P -d "$ADMIN" -Atc "SELECT usesuper FROM pg_user WHERE usename = current_user") == t ]] || die "needs a superuser"
port=$(P -d "$ADMIN" -Atc 'SHOW port')  # inet_server_port() is NULL over a Unix socket
RUN="${FIXTURE_RUN_DIR:-${TMPDIR:-/tmp}/pg_scripts_fixture}"; mkdir -p "$RUN"
# one supervisor per service / host / port / database
key="${PGSERVICE:-}_${PGHOST:-local}_${port}_$DB"; key=${key//[^A-Za-z0-9._-]/_}
PIDF="$RUN/$key.pid"; SLOG="$RUN/$key.log"
pidcol=pid; [[ $n -lt 902 ]] && pidcol=procpid
TMP=$(mktemp -d "${TMPDIR:-/tmp}/fixture.XXXXXX"); trap 'rm -rf "$TMP"' EXIT
contrib_dir() {
  if [[ -n "${FIXTURE_CONTRIB_DIR:-}" ]]; then echo "$FIXTURE_CONTRIB_DIR"
  else echo "$("${PG_CONFIG:-pg_config}" --sharedir)/contrib"; fi
}

# ---------------------------------------------------------------- build
build_sql() {
  local B=$1  # output file
  {
  echo "SET client_min_messages TO warning;"
  [[ $n -lt 900 ]] && echo "CREATE LANGUAGE plpgsql;"

  # --- bloat
  echo "CREATE TABLE bloat_upd (id serial PRIMARY KEY, val int, grp int, pad text) WITH (fillfactor = 70);"
  echo "INSERT INTO bloat_upd (val, grp, pad) SELECT g, g % 50, repeat(md5(g::text), 4) FROM generate_series(1, 100000) g;"
  echo "CREATE INDEX bloat_upd_val_idx ON bloat_upd (val);"
  echo "CREATE INDEX bloat_upd_grp_idx ON bloat_upd (grp);"
  echo "CREATE TABLE bloat_del (id int PRIMARY KEY, pad text);"
  echo "INSERT INTO bloat_del SELECT g, repeat('y', 200) FROM generate_series(1, 100000) g;"
  if [[ $n -ge 804 ]]; then
    echo "ALTER TABLE bloat_upd SET (autovacuum_enabled = false, toast.autovacuum_enabled = false);"
    echo "ALTER TABLE bloat_del SET (autovacuum_enabled = false, autovacuum_vacuum_scale_factor = 0.01, autovacuum_vacuum_threshold = 100, autovacuum_analyze_scale_factor = 0.02, autovacuum_vacuum_cost_delay = 5, autovacuum_freeze_max_age = 100000000);"
  fi
  # --- TOAST
  echo "CREATE TABLE toast_big (id int PRIMARY KEY, doc text, note text);"
  echo "ALTER TABLE toast_big ALTER doc SET STORAGE EXTERNAL;"
  echo "INSERT INTO toast_big SELECT g, array_to_string(ARRAY(SELECT md5(g::text || '-' || i::text) FROM generate_series(1, 1500) i), ''), 'n' || g::text FROM generate_series(1, 300) g;"
  [[ $n -ge 804 ]] && echo "ALTER TABLE toast_big SET (fillfactor = 90, autovacuum_vacuum_scale_factor = 0.05, toast.autovacuum_vacuum_scale_factor = 0.02, toast.autovacuum_vacuum_threshold = 50, toast.autovacuum_enabled = false, autovacuum_enabled = false);"
  [[ $n -ge 1300 ]] && echo "ALTER TABLE toast_big SET (autovacuum_vacuum_insert_threshold = 500, autovacuum_vacuum_insert_scale_factor = 0.1);"
  [[ $n -ge 906 ]] && echo "ALTER TABLE bloat_upd SET (parallel_workers = 2);"
  # 8.2/8.3: per-table autovacuum settings live in pg_autovacuum
  if [[ $n -lt 804 ]]; then
    echo "INSERT INTO pg_autovacuum VALUES ('bloat_upd'::regclass, false, -1, -1, -1, -1, -1, -1, -1, -1);"
    echo "INSERT INTO pg_autovacuum VALUES ('bloat_del'::regclass, false, 100, 0.01, 50, 0.02, 5, -1, -1, 100000000);"
    echo "INSERT INTO pg_autovacuum VALUES ('toast_big'::regclass, false, -1, 0.05, -1, -1, -1, -1, -1, -1);"
  fi

  # --- inheritance partitions (every version)
  echo "CREATE TABLE inh_parent (id int, created date, v text);"
  for m in 1 2 3; do
    echo "CREATE TABLE inh_child_$m (CHECK (created >= DATE '2026-0$m-01' AND created < DATE '2026-0$((m+1))-01')) INHERITS (inh_parent);"
    echo "INSERT INTO inh_child_$m SELECT g, DATE '2026-0$m-01' + (g % 28), md5(g::text) FROM generate_series(1, 20000) g;"
    echo "CREATE INDEX inh_child_${m}_created_idx ON inh_child_$m (created);"
  done

  # --- declarative partitions, two levels
  if [[ $n -ge 1000 ]]; then
    echo "CREATE TABLE part_events (id bigint NOT NULL, created date NOT NULL, region text NOT NULL, payload text) PARTITION BY RANGE (created);"
    for m in 1 2 3 4; do
      echo "CREATE TABLE part_events_2026_0$m PARTITION OF part_events FOR VALUES FROM ('2026-0$m-01') TO ('2026-0$((m+1))-01') PARTITION BY LIST (region);"
      for r in eu us; do
        echo "CREATE TABLE part_events_2026_0${m}_$r PARTITION OF part_events_2026_0$m FOR VALUES IN ('$r');"
      done
      [[ $n -ge 1100 ]] && echo "CREATE TABLE part_events_2026_0${m}_other PARTITION OF part_events_2026_0$m DEFAULT;"
    done
    if [[ $n -ge 1100 ]]; then
      echo "CREATE TABLE part_events_default PARTITION OF part_events DEFAULT;"
      echo "ALTER TABLE part_events ADD PRIMARY KEY (id, created, region);"
      echo "CREATE INDEX part_events_region_idx ON part_events (region, created);"
      echo "CREATE TABLE part_hash (id int NOT NULL, v text) PARTITION BY HASH (id);"
      for r in 0 1 2 3; do echo "CREATE TABLE part_hash_$r PARTITION OF part_hash FOR VALUES WITH (MODULUS 4, REMAINDER $r);"; done
      echo "CREATE INDEX part_hash_id_idx ON part_hash (id);"
      echo "INSERT INTO part_hash SELECT g, md5(g::text) FROM generate_series(1, 20000) g;"
      echo "INSERT INTO part_events SELECT g, DATE '2026-01-01' + (g % 150), (ARRAY['eu','us','ap'])[1 + g % 3], md5(g::text) FROM generate_series(1, 60000) g;"
    else
      for m in 1 2 3 4; do for r in eu us; do
        echo "CREATE INDEX part_events_2026_0${m}_${r}_created_idx ON part_events_2026_0${m}_$r (created);"
      done; done
      echo "INSERT INTO part_events SELECT g, DATE '2026-01-01' + (g % 119), (ARRAY['eu','us'])[1 + g % 2], md5(g::text) FROM generate_series(1, 60000) g;"
    fi
  fi

  # --- matviews / unlogged
  if [[ $n -ge 903 ]]; then
    echo "CREATE MATERIALIZED VIEW mv_grp AS SELECT grp, count(*) AS n, sum(val) AS s FROM bloat_upd GROUP BY grp;"
    echo "CREATE UNIQUE INDEX mv_grp_grp_idx ON mv_grp (grp);"
    echo "CREATE MATERIALIZED VIEW mv_empty AS SELECT id, created FROM inh_parent WITH NO DATA;"
  fi
  [[ $n -ge 901 ]] && { echo "CREATE UNLOGGED TABLE unlogged_cache (k text PRIMARY KEY, v text);"
                        echo "INSERT INTO unlogged_cache SELECT md5(g::text), repeat('u', 100) FROM generate_series(1, 20000) g;"
                        echo "CREATE UNLOGGED TABLE unlogged_empty (k int, v text);"
                        echo "ANALYZE unlogged_empty;"; }

  # --- sequences
  echo "CREATE TABLE seq_nearly_full (id serial PRIMARY KEY, v text);"
  echo "INSERT INTO seq_nearly_full (v) SELECT 'x' FROM generate_series(1, 100);"
  echo "SELECT setval('seq_nearly_full_id_seq', 2000000000);"
  echo "INSERT INTO seq_nearly_full (v) VALUES ('near the int limit');"
  echo "CREATE SEQUENCE seq_cycle MINVALUE 1 MAXVALUE 1000 CYCLE;"
  echo "SELECT setval('seq_cycle', 990);"
  echo "CREATE SEQUENCE seq_unused;"
  if [[ $n -ge 1000 ]]; then
    echo "CREATE SEQUENCE seq_small AS smallint;"
    echo "SELECT setval('seq_small', 30000);"
    echo "CREATE TABLE ident_tbl (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, v text);"
    echo "INSERT INTO ident_tbl (v) SELECT md5(g::text) FROM generate_series(1, 1000) g;"
  fi

  # --- index zoo
  echo "CREATE TABLE idx_zoo (id int PRIMARY KEY, a int, b int, c text, tags int[], box_col box, ts timestamp);"
  echo "INSERT INTO idx_zoo SELECT g, g % 1000, g % 7, md5(g::text), ARRAY[g % 10, g % 100], box(point(g % 100, g % 50), point(g % 100 + 1, g % 50 + 1)), TIMESTAMP '2026-01-01' + g * INTERVAL '1 minute' FROM generate_series(1, 50000) g;"
  echo "CREATE INDEX idx_zoo_a ON idx_zoo (a);"
  echo "CREATE INDEX idx_zoo_a_dup ON idx_zoo (a);"
  echo "CREATE INDEX idx_zoo_ab ON idx_zoo (a, b);"
  echo "CREATE INDEX idx_zoo_partial ON idx_zoo (b) WHERE b = 3;"
  echo "CREATE INDEX idx_zoo_expr ON idx_zoo (lower(c));"
  echo "CREATE INDEX idx_zoo_unused ON idx_zoo (c, b);"
  echo "CREATE INDEX idx_zoo_tags_gin ON idx_zoo USING gin (tags);"
  echo "CREATE INDEX idx_zoo_box_gist ON idx_zoo USING gist (box_col);"
  [[ $n -ge 803 ]] && echo "CREATE INDEX idx_zoo_c_fts ON idx_zoo USING gin (to_tsvector('english', c));"
  [[ $n -ge 902 ]] && echo "CREATE INDEX idx_zoo_spgist ON idx_zoo USING spgist (c);"
  [[ $n -ge 905 ]] && echo "CREATE INDEX idx_zoo_brin ON idx_zoo USING brin (ts);"
  [[ $n -ge 1000 ]] && echo "CREATE INDEX idx_zoo_hash ON idx_zoo USING hash (c);"
  [[ $n -ge 1100 ]] && echo "CREATE INDEX idx_zoo_incl ON idx_zoo (b) INCLUDE (c);"
  if [[ $n -ge 904 ]]; then
    echo "CREATE TABLE docs_jsonb (id int PRIMARY KEY, j jsonb);"
    echo "INSERT INTO docs_jsonb SELECT g, ('{\"k\": ' || g::text || ', \"tags\": [\"t' || (g % 10)::text || '\"]}')::jsonb FROM generate_series(1, 20000) g;"
    echo "CREATE INDEX docs_jsonb_gin ON docs_jsonb USING gin (j jsonb_path_ops);"
  fi
  # duplicates for the invalid index (CREATE UNIQUE INDEX CONCURRENTLY fails -> INVALID)
  echo "CREATE TABLE inv_tbl (k int, v text);"
  echo "INSERT INTO inv_tbl SELECT g % 500, 'v' FROM generate_series(1, 5000) g;"

  # --- FK without index
  echo "CREATE TABLE fk_parent (id int PRIMARY KEY, name text);"
  echo "INSERT INTO fk_parent SELECT g, 'p' || g::text FROM generate_series(1, 2000) g;"
  echo "CREATE TABLE fk_child_noidx (id int PRIMARY KEY, parent_id int REFERENCES fk_parent (id), amount numeric);"
  echo "INSERT INTO fk_child_noidx SELECT g, 1 + g % 2000, g * 1.5 FROM generate_series(1, 30000) g;"
  echo "CREATE TABLE fk_child_idx (id int PRIMARY KEY, parent_id int REFERENCES fk_parent (id) ON DELETE CASCADE);"
  echo "CREATE INDEX fk_child_idx_parent ON fk_child_idx (parent_id);"
  echo "INSERT INTO fk_child_idx SELECT g, 1 + g % 2000 FROM generate_series(1, 5000) g;"
  echo "CREATE TABLE no_pk (a int, b text);"
  echo "INSERT INTO no_pk SELECT g, 'x' FROM generate_series(1, 1000) g;"
  echo "CREATE TABLE never_analyzed (a int, b text);"
  echo "INSERT INTO never_analyzed SELECT g, 'x' FROM generate_series(1, 5000) g;"
  [[ $n -ge 804 ]] && echo "ALTER TABLE never_analyzed SET (autovacuum_enabled = false);"
  [[ $n -lt 804 ]] && echo "INSERT INTO pg_autovacuum VALUES ('never_analyzed'::regclass, false, -1, -1, -1, -1, -1, -1, -1, -1);"
  [[ $n -le 1100 ]] && { echo "CREATE TABLE with_oids (a int) WITH OIDS;"; echo "INSERT INTO with_oids SELECT g FROM generate_series(1, 100) g;"; }
  # the COPY session's target: empty and analyzed, so reltuples is 0
  echo "CREATE TABLE copy_target (id int, v text);"
  echo "ANALYZE copy_target;"
  # the lock target for the background sessions
  echo "CREATE TABLE lock_tbl (id int PRIMARY KEY, v int);"
  echo "INSERT INTO lock_tbl SELECT g, 0 FROM generate_series(1, 10) g;"

  # --- types, domains, collations
  echo "CREATE DOMAIN email_addr AS text CHECK (VALUE LIKE '%@%');"
  echo "CREATE DOMAIN positive_int AS int NOT NULL CHECK (VALUE > 0);"
  echo "CREATE TYPE address AS (street text, city text, zip varchar(10));"
  [[ $n -ge 803 ]] && echo "CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');"
  [[ $n -ge 902 ]] && echo "CREATE TYPE float_range AS RANGE (subtype = float8);"
  echo "CREATE TABLE typed_tbl (id positive_int PRIMARY KEY, mail email_addr, addr address$([[ $n -ge 803 ]] && echo ', feeling mood')$([[ $n -ge 902 ]] && echo ', fr float_range'));"
  echo "INSERT INTO typed_tbl (id, mail, addr) SELECT g, 'u' || g::text || '@example.com', ROW('Main St ' || g::text, 'City', '12345')::address FROM generate_series(1, 1000) g;"
  if [[ $n -ge 901 ]]; then
    echo "CREATE COLLATION fix_c FROM \"C\";"
    echo "CREATE TABLE coll_tbl (id int, name_c text COLLATE \"C\", name_fix text COLLATE fix_c, name_posix text COLLATE \"POSIX\");"
    echo "INSERT INTO coll_tbl SELECT g, md5(g::text), md5(g::text), md5(g::text) FROM generate_series(1, 1000) g;"
    echo "CREATE INDEX coll_tbl_name_c_idx ON coll_tbl (name_c);"
  fi
  if [[ $n -ge 1000 ]] && [[ -n $(P -d "$ADMIN" -Atc "SELECT 1 FROM pg_collation WHERE collprovider = 'i' LIMIT 1") ]]; then
    echo "CREATE COLLATION fix_icu_de (provider = icu, locale = 'de-DE');"
    echo "ALTER TABLE coll_tbl ADD COLUMN name_icu text COLLATE fix_icu_de;"
    echo "UPDATE coll_tbl SET name_icu = name_c;"
    echo "CREATE INDEX coll_tbl_name_icu_idx ON coll_tbl (name_icu);"
  fi
  [[ $n -ge 900 ]] && { echo "CREATE TABLE excl_tbl (id int, b box, EXCLUDE USING gist (b WITH &&));"
                        echo "INSERT INTO excl_tbl SELECT g, box(point(g * 3, 0), point(g * 3 + 1, 1)) FROM generate_series(1, 500) g;"; }
  [[ $n -ge 1000 ]] && echo "CREATE STATISTICS idx_zoo_ab_stats (dependencies) ON a, b FROM idx_zoo;"
  [[ $n -ge 1400 ]] && echo "CREATE STATISTICS idx_zoo_expr_stats ON (a % 10), b FROM idx_zoo;"

  # --- functions, trigger, view
  echo "CREATE FUNCTION f_sql_add(int, int) RETURNS int AS 'SELECT \$1 + \$2' LANGUAGE sql IMMUTABLE;"
  echo "CREATE FUNCTION f_sql_add(numeric, numeric) RETURNS numeric AS 'SELECT \$1 + \$2' LANGUAGE sql IMMUTABLE;"
  cat <<'EOF'
CREATE FUNCTION f_plpgsql_count(p_grp int) RETURNS bigint AS $body$
DECLARE
  r bigint;
BEGIN
  SELECT count(*) INTO r FROM bloat_upd WHERE grp = p_grp;
  RETURN r;
END
$body$ LANGUAGE plpgsql STABLE;
CREATE FUNCTION f_secdef() RETURNS int AS $body$ SELECT count(*)::int FROM fk_parent $body$ LANGUAGE sql SECURITY DEFINER;
CREATE FUNCTION f_slow(p int) RETURNS int AS $body$
DECLARE
  s int := 0;
BEGIN
  FOR i IN 1 .. p LOOP
    s := s + i % 7;
  END LOOP;
  RETURN s;
END
$body$ LANGUAGE plpgsql;
CREATE FUNCTION trg_touch() RETURNS trigger AS $body$
BEGIN
  NEW.note := coalesce(NEW.note, '') || '+';
  RETURN NEW;
END
$body$ LANGUAGE plpgsql;
CREATE TRIGGER toast_big_touch BEFORE UPDATE ON toast_big FOR EACH ROW EXECUTE PROCEDURE trg_touch();
CREATE VIEW v_fk_summary AS SELECT p.id, p.name, count(c.id) AS children FROM fk_parent p LEFT JOIN fk_child_noidx c ON c.parent_id = p.id GROUP BY p.id, p.name;
COMMENT ON TABLE bloat_upd IS 'fixture: dead tuples from mass UPDATE/DELETE';
EOF

  # --- a schema outside search_path, with names that need quoting
  cat <<'EOF'
CREATE SCHEMA "Odd Schema";
CREATE TABLE "Odd Schema"."Mixed Case" ("Id" int PRIMARY KEY, "Some Col" text, "select" int);
INSERT INTO "Odd Schema"."Mixed Case" SELECT g, md5(g::text), g FROM generate_series(1, 5000) g;
CREATE INDEX "Idx With Space" ON "Odd Schema"."Mixed Case" ("Some Col");
CREATE INDEX "Idx With Space Dup" ON "Odd Schema"."Mixed Case" ("Some Col");
CREATE SEQUENCE "Odd Schema"."Seq-Dash";
CREATE TABLE "Odd Schema".child_of_odd (id int, odd_id int REFERENCES "Odd Schema"."Mixed Case" ("Id"));
INSERT INTO "Odd Schema".child_of_odd SELECT g, 1 + g % 5000 FROM generate_series(1, 5000) g;
CREATE FUNCTION "Odd Schema"."Odd Func"(int) RETURNS int AS 'SELECT $1 * 2' LANGUAGE sql;
UPDATE "Odd Schema"."Mixed Case" SET "select" = "select" + 1 WHERE "Id" % 2 = 0;
EOF
  [[ $n -ge 1100 ]] && cat <<'EOF'
CREATE TABLE "Odd Schema"."Part Odd" (id int NOT NULL, k text NOT NULL) PARTITION BY LIST (k);
CREATE TABLE "Odd Schema"."Part Odd A" PARTITION OF "Odd Schema"."Part Odd" FOR VALUES IN ('a') PARTITION BY RANGE (id);
CREATE TABLE "Odd Schema"."Part Odd A1" PARTITION OF "Odd Schema"."Part Odd A" FOR VALUES FROM (0) TO (1000);
CREATE INDEX "Part Odd Idx" ON "Odd Schema"."Part Odd" (id);
INSERT INTO "Odd Schema"."Part Odd" SELECT g, 'a' FROM generate_series(0, 999) g;
EOF

  # --- roles, grants, publication, large objects
  echo "GRANT SELECT ON bloat_upd, fk_parent TO fix_reader;"
  echo "GRANT ALL ON toast_big TO fix_writer;"
  echo "GRANT USAGE ON SCHEMA \"Odd Schema\" TO fix_reader;"
  echo "ALTER TABLE no_pk OWNER TO fix_writer;"
  echo "SELECT lo_create(0) FROM generate_series(1, 3);"
  [[ $n -ge 1000 ]] && echo "CREATE PUBLICATION fix_pub FOR TABLE fk_parent, idx_zoo;"

  # --- the bloat itself, then statistics (never_analyzed stays without)
  echo "UPDATE bloat_upd SET val = val + 1;"
  echo "UPDATE bloat_upd SET pad = md5(pad) WHERE id % 2 = 0;"
  echo "DELETE FROM bloat_upd WHERE id % 10 IN (1, 2, 3);"
  echo "DELETE FROM bloat_del WHERE id % 10 <> 0;"
  echo "UPDATE toast_big SET doc = doc || 'x' WHERE id % 2 = 0;"
  echo "UPDATE idx_zoo SET b = b + 1 WHERE id % 5 = 0;"
  for t in bloat_upd bloat_del toast_big inh_parent inh_child_1 inh_child_2 inh_child_3 idx_zoo inv_tbl fk_parent \
           fk_child_noidx fk_child_idx no_pk lock_tbl typed_tbl seq_nearly_full '"Odd Schema"."Mixed Case"'; do
    echo "ANALYZE $t;"
  done
  [[ $n -ge 1000 ]] && echo "ANALYZE part_events;"
  [[ $n -ge 1100 ]] && echo "ANALYZE part_hash;"
  [[ $n -ge 901 ]] && echo "ANALYZE coll_tbl; ANALYZE unlogged_cache;"
  # an if, not [[ ]] &&: as the group's last command a false test would make
  # build_sql fail under set -e on the versions without jsonb
  if [[ $n -ge 904 ]]; then echo "ANALYZE docs_jsonb;"; fi
  } > "$B"
}

install_extensions() {
  local e f
  if [[ $n -ge 901 ]]; then
    for e in pg_stat_statements pgstattuple pg_buffercache; do
      P -d "$DB" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION $e" >/dev/null || die "CREATE EXTENSION $e failed"
    done
  else
    for f in pgstattuple pg_buffercache $([[ $n -ge 804 ]] && echo pg_stat_statements); do
      [[ -f "$(contrib_dir)/$f.sql" ]] || die "missing $(contrib_dir)/$f.sql (set FIXTURE_CONTRIB_DIR or PG_CONFIG)"
      P -d "$DB" -v ON_ERROR_STOP=1 -f "$(contrib_dir)/$f.sql" >/dev/null 2>"$TMP/ext.err" || { cat "$TMP/ext.err" >&2; die "$f.sql failed"; }
    done
  fi
}

do_build() {
  local have owned exists r
  exists=$(P -d "$ADMIN" -Atc "SELECT 1 FROM pg_database WHERE datname = '$DB'")
  owned=$(P -d "$DB" -Atc "SELECT 1 FROM pg_class WHERE relname = 'fixture_info' AND relkind = 'r'" 2>/dev/null || true)
  have=$(P -d "$DB" -Atc "SELECT fixture_version FROM fixture_info" 2>/dev/null || true)
  if [[ $rebuild -eq 0 && "$have" == "$FIXTURE_VERSION" ]]; then echo "fixture pg$v: $DB already at version $FIXTURE_VERSION"; return 0; fi
  # never drop a database this script didn't create
  [[ -z "$exists" || -n "$owned" ]] || die "database $DB exists and was not created by this fixture (no fixture_info): drop it or set FIXDB"
  do_stop >/dev/null
  P -d "$ADMIN" -c "SET client_min_messages TO warning" -c "DROP DATABASE IF EXISTS $DB" >/dev/null || die "cannot drop $DB (sessions connected?)"
  P -d "$ADMIN" -v ON_ERROR_STOP=1 -c "CREATE DATABASE $DB" >/dev/null || die "CREATE DATABASE failed"
  # the marker first, so a build that fails halfway can still be dropped next time;
  # its row (the version) is written last, when everything is in place
  P -d "$DB" -v ON_ERROR_STOP=1 -c "CREATE TABLE fixture_info (fixture_version int, built_at timestamptz)" >/dev/null
  for r in fix_reader fix_writer; do
    [[ -n $(P -d "$ADMIN" -Atc "SELECT 1 FROM pg_roles WHERE rolname = '$r'") ]] || P -d "$ADMIN" -c "CREATE ROLE $r NOLOGIN" >/dev/null
  done
  install_extensions
  build_sql "$TMP/build.sql"
  P -d "$DB" -v ON_ERROR_STOP=1 -f "$TMP/build.sql" >"$TMP/build.out" 2>&1 || { cat "$TMP/build.out" >&2; die "build failed"; }
  # INVALID index: a unique CREATE INDEX CONCURRENTLY over duplicate keys fails and leaves it behind
  P -d "$DB" -c "CREATE UNIQUE INDEX CONCURRENTLY inv_tbl_k_invalid ON inv_tbl (k)" >/dev/null 2>&1 || true  # meant to fail
  # 8.2 checks uniqueness in the first pass and leaves nothing: mark one invalid by hand
  [[ $n -lt 803 ]] && P -d "$DB" -c "CREATE INDEX inv_tbl_k_invalid ON inv_tbl (k)" \
      -c "UPDATE pg_index SET indisvalid = false WHERE indexrelid = 'inv_tbl_k_invalid'::regclass" >/dev/null
  [[ $(P -d "$DB" -Atc "SELECT count(*) FROM pg_index WHERE NOT indisvalid") -ge 1 ]] || die "no invalid index"
  # complete: only now the version row, which makes the next run skip the build
  P -d "$DB" -v ON_ERROR_STOP=1 -c "INSERT INTO fixture_info VALUES ($FIXTURE_VERSION, now())" >/dev/null
  echo "fixture pg$v: $DB built (version $FIXTURE_VERSION, $(P -d "$DB" -Atc "SELECT pg_size_pretty(pg_database_size(current_database()))"))"
}

# ---------------------------------------------------------------- load
do_load() {
  local L="$TMP/load.sql" i
  {
    echo "SET client_min_messages TO warning;"
    # DELETE activity too (rows from the previous load), and keeps no_pk from growing
    echo "DELETE FROM no_pk WHERE b = 'load';"
    for i in $(seq 1 60); do
      echo "SELECT count(*) FROM bloat_upd WHERE id = $i;"
      echo "SELECT * FROM idx_zoo WHERE a = $((i * 7 % 1000)) AND b = $((i % 7));"
      echo "SELECT id FROM fk_child_noidx WHERE parent_id = $i;"
      echo "SELECT f_plpgsql_count($((i % 50)));"
      echo "SELECT f_sql_add($i, 1), f_sql_add($i.5, 1);"
      echo "UPDATE fk_parent SET name = name WHERE id = $i;"
      echo "INSERT INTO no_pk VALUES ($i, 'load');"
      echo "SELECT nextval('seq_cycle');"
      echo "SELECT \"Odd Schema\".\"Odd Func\"($i), count(*) FROM \"Odd Schema\".\"Mixed Case\" WHERE \"Id\" < $i;"
    done
    for i in $(seq 1 10); do
      echo "SELECT count(*) FROM inh_parent WHERE created = DATE '2026-02-0$((i % 9 + 1))';"
      echo "SELECT sum(length(doc)) FROM toast_big WHERE id = $i;"
      echo "SELECT f_slow(20000);"
      echo "SELECT f_secdef();"
      echo "SELECT count(*) FROM idx_zoo WHERE tags @> ARRAY[$i];"
      [[ $n -ge 1000 ]] && echo "SELECT count(*) FROM part_events WHERE created = DATE '2026-03-0$((i % 9 + 1))' AND region = 'eu';"
      [[ $n -ge 904 ]] && echo "SELECT count(*) FROM docs_jsonb WHERE j @> '{\"k\": $i}';"
      [[ $n -ge 903 ]] && echo "SELECT * FROM mv_grp WHERE grp = $i;"
      [[ $n -ge 901 ]] && echo "SELECT v FROM unlogged_cache WHERE k = md5('$i');"
    done
    # heavy ones: sequential scans, a sort spilling to temp files, a big join
    echo "SET work_mem = '64kB';"
    for i in 1 2 3; do
      echo "SELECT count(*) FROM (SELECT pad FROM bloat_upd ORDER BY pad) s;"
      echo "SELECT count(*) FROM fk_child_noidx c JOIN fk_parent p ON p.id = c.parent_id;"
      echo "SELECT * FROM v_fk_summary ORDER BY children DESC LIMIT 5;"
    done
    echo "RESET work_mem;"
    if [[ $n -ge 903 ]]; then echo "REFRESH MATERIALIZED VIEW mv_grp;"; fi
  } > "$L"
  P -d "$DB" -f "$L" >/dev/null 2>"$TMP/load.err"
  if grep -q 'ERROR' "$TMP/load.err"; then cat "$TMP/load.err" >&2; die "load had errors"; fi
  echo "fixture pg$v: load done ($(grep -c ';' "$L") statements)"
}

# ---------------------------------------------------------------- sessions
# Each session is a psql reading from a FIFO the supervisor keeps open, so it
# stays idle (in transaction) as long as the supervisor wants. The supervisor
# respawns a session whose backend is gone (kill_* scripts) or whose psql died.
supervise() {
  local fifo_dir="$RUN/$key.fifo" s
  mkdir -p "$fifo_dir"
  declare -A PSQL FD BPID
  SQL_idle_tx="BEGIN; SELECT count(*) FROM bloat_upd;"
  SQL_blocker="BEGIN; UPDATE lock_tbl SET v = v + 1 WHERE id = 1;"
  SQL_blocked="UPDATE lock_tbl SET v = v + 1 WHERE id = 1;"
  SQL_active="SELECT pg_sleep(86400);"
  # COPY data comes from the same FIFO, which never sends it: stays in progress
  SQL_copy="COPY copy_target FROM STDIN;"
  start_one() {  # $1 = name
    local s=$1 f="$fifo_dir/$1" pf="$fifo_dir/$1.pid" sqlv="SQL_$1" appn="" i
    rm -f "$f" "$pf"; mkfifo "$f"
    [[ $n -ge 900 ]] && appn="SET application_name = 'fixture_$s';"
    psql -X -q -At -d "$DB" < "$f" >/dev/null 2>&1 &
    PSQL[$s]=$!
    exec {fd}>"$f"; FD[$s]=$fd
    # pid first, then the session's SQL, then (client side, no query, so the
    # session still shows its own statement) a ready file once that SQL is done
    rm -f "$pf.ready"
    printf '%s\n\\o %s\nSELECT pg_backend_pid();\n\\o\n%s\n\\! touch %s\n' "$appn" "$pf" "${!sqlv}" "$pf.ready" >&$fd
    for i in $(seq 1 100); do [[ -s "$pf" ]] && break; sleep 0.1; done
    # idle_tx and the blocker must hold their transaction (and row lock) before
    # the next session starts; active and blocked never finish their statement
    if [[ $s == idle_tx || $s == blocker ]]; then
      for i in $(seq 1 100); do [[ -e "$pf.ready" ]] && break; sleep 0.1; done
    fi
    BPID[$s]=$(tr -dc '0-9' < "$pf" 2>/dev/null || true)
  }
  stop_one() {  # every step may find its target already gone (a kill_* script got there first)
    local s=$1
    if [[ -n "${FD[$s]:-}" ]]; then eval "exec ${FD[$s]}>&-" || true; fi
    if [[ -n "${PSQL[$s]:-}" ]]; then
      kill "${PSQL[$s]}" 2>/dev/null || true
      wait "${PSQL[$s]}" 2>/dev/null || true
    fi
    if [[ -n "${BPID[$s]:-}" ]]; then end_backends "$pidcol = ${BPID[$s]}"; fi
    unset 'FD[$s]' 'PSQL[$s]' 'BPID[$s]'
  }
  alive() {  # backend still there and, for active/blocked, still running its query
    local s=$1 busy=""   # (before 8.4 a kill_* script can only cancel it, leaving it idle)
    if [[ $s == active || $s == blocked || $s == copy ]]; then
      if [[ $n -ge 902 ]]; then busy="AND state = 'active'"; else busy="AND current_query NOT LIKE '<IDLE>%'"; fi
    fi
    [[ -n "${BPID[$s]:-}" ]] && kill -0 "${PSQL[$s]}" 2>/dev/null &&
      [[ -n $(P -d "$ADMIN" -Atc "SELECT 1 FROM pg_stat_activity WHERE $pidcol = ${BPID[$s]} $busy" 2>/dev/null) ]]
  }
  trap 'for s in blocked blocker idle_tx active copy; do stop_one $s; done; rm -rf "$fifo_dir"; exit 0' TERM INT
  while :; do
    for s in idle_tx active copy; do alive $s || { stop_one $s; start_one $s; echo "$(date +%T) (re)started $s pid ${BPID[$s]}"; }; done
    if ! alive blocker || ! alive blocked; then
      stop_one blocked; stop_one blocker
      start_one blocker; start_one blocked
      echo "$(date +%T) (re)started blocker pid ${BPID[blocker]} / blocked pid ${BPID[blocked]}"
    fi
    sleep 2 & wait $!
  done
}

do_start() {
  if [[ -f "$PIDF" ]] && kill -0 "$(cat "$PIDF")" 2>/dev/null; then echo "fixture pg$v: sessions already running"; return 0; fi
  nohup "$0" _supervise >"$SLOG" 2>&1 &
  echo $! > "$PIDF"
  local i c=0
  for i in $(seq 1 50); do
    c=$(P -d "$ADMIN" -Atc "SELECT count(*) FROM pg_stat_activity WHERE datname = '$DB' AND $pidcol <> pg_backend_pid()")
    [[ $c -ge 5 ]] && break; sleep 0.2
  done
  [[ $c -ge 5 ]] || die "sessions did not come up (see $SLOG)"
  echo "fixture pg$v: 5 sessions up (supervisor $(cat "$PIDF"))"
}

# end the backends matching a pg_stat_activity condition; pg_terminate_backend()
# comes in 8.4, before that only the running query can be cancelled (an idle
# session ends when its psql exits, which the supervisor takes care of)
end_backends() {
  local f=pg_terminate_backend
  [[ $n -lt 804 ]] && f=pg_cancel_backend
  P -d "$ADMIN" -Atc "SELECT $f($pidcol) FROM pg_stat_activity WHERE $1" >/dev/null 2>&1 || true
}

do_stop() {
  if [[ -f "$PIDF" ]]; then
    local p; p=$(cat "$PIDF")
    if kill -0 "$p" 2>/dev/null; then kill "$p" 2>/dev/null || true; local i; for i in $(seq 1 50); do kill -0 "$p" 2>/dev/null || break; sleep 0.1; done; fi
    rm -f "$PIDF"
  fi
  # leftovers (supervisor killed hard): any backend still in the database,
  # only when the database is the fixture's own
  if [[ -n $(P -d "$DB" -Atc "SELECT 1 FROM pg_class WHERE relname = 'fixture_info' AND relkind = 'r'" 2>/dev/null || true) ]]; then
    end_backends "datname = '$DB' AND $pidcol <> pg_backend_pid()"
  fi
  echo "fixture pg$v: sessions stopped"
}

do_status() {
  local q="SELECT $pidcol, $([[ $n -ge 900 ]] && echo 'application_name,') $([[ $n -ge 902 ]] && echo 'state, query' || echo 'current_query'), now() - $([[ $n -ge 803 ]] && echo xact_start || echo query_start) AS age FROM pg_stat_activity WHERE datname = '$DB'"
  P -d "$ADMIN" -c "$q"
}

case "$cmd" in
  all)        do_build && do_load ;;
  build)      do_build ;;
  load)       do_load ;;
  start)      do_start ;;
  stop)       do_stop ;;
  status)     do_status ;;
  _supervise) trap - EXIT; rm -rf "$TMP"; supervise ;;
  *) die "unknown command $cmd" ;;
esac
