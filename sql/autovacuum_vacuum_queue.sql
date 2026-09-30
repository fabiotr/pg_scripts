-- https://gitlab.com/snippets/1889668
WITH table_opts AS (
  SELECT
    pg_class.oid,
    relname,
    nspname,
    array_to_string(reloptions, '') AS relopts
  FROM pg_class
  JOIN pg_namespace ns ON relnamespace = ns.oid
), vacuum_settings AS (
  SELECT
    oid,
    relname,
    nspname,
    CASE
      WHEN relopts LIKE '%autovacuum_vacuum_threshold%' THEN regexp_replace(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*', E'\\1')::int8
      ELSE current_setting('autovacuum_vacuum_threshold')::int8
    END AS autovacuum_vacuum_threshold,
    CASE
      WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%' THEN regexp_replace(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*', E'\\1')::numeric
      ELSE current_setting('autovacuum_vacuum_scale_factor')::numeric
    END AS autovacuum_vacuum_scale_factor,
    CASE WHEN relopts ~ 'autovacuum_enabled=(false|off)' THEN FALSE ELSE TRUE END AS autovacuum_enabled
  FROM table_opts
), p AS (
  SELECT *
  FROM pg_stat_progress_vacuum
)
SELECT
  --vacuum_settings.oid,
  coalesce(
    coalesce(nullif(vacuum_settings.nspname, 'public') || '.', '') || vacuum_settings.relname, -- current DB
    format('[something in "%I"]', p.datname)
  ) AS table,
  round((100 * psat.n_dead_tup::numeric / nullif(pg_class.reltuples, 0))::numeric, 2) AS dead_tup_pct,
  pg_class.reltuples::numeric,
  psat.n_dead_tup,
  'vt: ' || vacuum_settings.autovacuum_vacuum_threshold
    || ', vsf: ' || vacuum_settings.autovacuum_vacuum_scale_factor 
    || CASE WHEN NOT autovacuum_enabled THEN ', DISABLED' ELSE ', enabled' END AS "effective_settings",
  CASE
    WHEN last_autovacuum > coalesce(last_vacuum, '0001-01-01') THEN left(last_autovacuum::text, 19) || ' (auto)'
    WHEN last_vacuum IS NOT NULL THEN left(last_vacuum::text, 19) || ' (manual)'
    ELSE NULL
  END AS "last_vacuumed",
  coalesce(p.phase, '~~~ in queue ~~~') AS status,
  p.pid AS pid,
  CASE
    WHEN a.query ~ '^autovacuum.*to prevent wraparound' THEN 'wraparound' 
    WHEN a.query ~ '^vacuum' THEN 'user'
    WHEN a.pid IS NULL THEN NULL
    ELSE 'regular'
  END AS mode,
  CASE WHEN a.pid IS NULL THEN NULL ELSE coalesce(wait_event_type ||'.'|| wait_event, 'f') END AS waiting,
  round(100.0 * p.heap_blks_scanned / nullif(p.heap_blks_total, 0), 1) AS scanned_pct,
  round(100.0 * p.heap_blks_vacuumed / nullif(p.heap_blks_total, 0), 1) AS vacuumed_pct,
  p.index_vacuum_count,
  CASE 
    WHEN psat.relid IS NOT NULL AND p.relid IS NOT NULL THEN
      (SELECT count(*) FROM pg_index WHERE indrelid = psat.relid)
    ELSE NULL
  END AS index_count
FROM pg_stat_all_tables psat
JOIN pg_class ON psat.relid = pg_class.oid
JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
FULL OUTER JOIN p ON p.relid = psat.relid AND p.datname = current_database()
LEFT JOIN pg_stat_activity a USING (pid)
WHERE
  psat.relid IS NULL
  OR autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < psat.n_dead_tup;
