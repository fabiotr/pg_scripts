SELECT
  p.pid,
  now() - a.xact_start AS duration,
  coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
  --p.datname AS database,
  c.relnamespace::regnamespace || '.' || c.relname AS table,
  command,
  type,
  pg_size_pretty(bytes_total)                                                         AS "Size total",
  pg_size_pretty(bytes_processed)                                                     AS "Size copied",
  trunc(bytes_processed::numeric * 100 / bytes_total::numeric, 1)                     AS "% Copied",
  reltuples                                                                           AS "Rows Total",
  trunc((tuples_processed::numeric * 100) / (reltuples - tuples_excluded)::numeric,1) AS "% Rows Copied",
  trunc(tuples_excluded::numeric * 100 / reltuples::numeric)                          AS "% Rows excluded"
FROM
  pg_stat_progress_copy p
  JOIN pg_stat_activity a using (pid)
  JOIN pg_class c ON c.oid = p.relid
ORDER BY now() - a.xact_start DESC;
