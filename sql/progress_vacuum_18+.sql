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
  p.indexes_total,
  p.indexes_processed AS indexes_scanned,
  round(100.0 * p.heap_blks_vacuumed / p.heap_blks_total, 1) AS vacuumed_pct,
  round(100.0 * p.dead_tuple_bytes / p.max_dead_tuple_bytes,1) AS dead_pct,
  CASE WHEN current_setting('track_cost_delay_timing') = 'on'
      THEN to_char(delay_time * INTERVAL '1 millisecond', 'HH24:MI:SS,US')
      ELSE 'disabled' END AS delay_time
FROM 
  pg_stat_progress_vacuum p
  JOIN pg_stat_activity a using (pid)
  JOIN pg_class c ON c.oid = p.relid
ORDER BY now() - a.xact_start DESC;
