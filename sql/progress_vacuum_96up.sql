SELECT
  p.pid,
  now() - a.xact_start AS duration,
  coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
  CASE
    WHEN a.query ~*'^autovacuum.*to prevent wraparound' THEN 'wraparound'
    WHEN a.query ~*'^vacuum' THEN 'user'
    ELSE 'regular'
  END AS mode,
  p.datname AS database,
  c.relnamespace::regnamespace || '.' || p.relid::regclass AS table,
  p.phase,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
  pg_size_pretty(pg_table_size(relid)) AS table_size,
  pg_size_pretty(p.heap_blks_total * current_setting('block_size')::int) AS vacuum_size,
  pg_size_pretty(p.heap_blks_scanned * current_setting('block_size')::int) AS scanned,
  pg_size_pretty(p.heap_blks_vacuumed * current_setting('block_size')::int) AS vacuumed,
  round(100.0 * p.heap_blks_scanned / p.heap_blks_total, 1) AS scanned_pct,
  i.index_qt,
  p.index_vacuum_count AS indexes_scanned,
  round(100.0 * p.heap_blks_vacuumed / p.heap_blks_total, 1) AS vacuumed_pct,
  round(100.0 * p.num_dead_tuples / p.max_dead_tuples,1) AS dead_pct
FROM 
  pg_stat_progress_vacuum p
  JOIN pg_stat_activity a using (pid)
  JOIN pg_class c ON c.oid = p.relid
  JOIN (SELECT indrelid, count(1) AS index_qt FROM pg_index GROUP BY indrelid) i ON i.indrelid = c.oid
ORDER BY now() - a.xact_start DESC;
