SELECT
  p.pid,
  now() - a.xact_start AS duration,
  coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
  --p.datname AS database,
  c.relnamespace::regnamespace || '.' || p.relid::regclass AS table,
  p.phase,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
  pg_size_pretty(pg_table_size(relid)) AS table_size,
  pg_size_pretty(p.sample_blks_total * current_setting('block_size')::int) AS analyze_size,
  pg_size_pretty(p.sample_blks_scanned * current_setting('block_size')::int) AS scanned_size,
  round(100.0 * sample_blks_scanned / p.sample_blks_total, 1) AS scanned_pct,
  ext_stats_total,
  ext_stats_computed,
  child_tables_total,
  child_tables_done,
  c.relname AS current_child_table
FROM
  pg_stat_progress_analyze p
  JOIN pg_stat_activity a using (pid)
  JOIN pg_class c ON c.oid = p.relid
  JOIN pg_class cc ON c.oid = p.current_child_table_relid
ORDER BY now() - a.xact_start DESC;
