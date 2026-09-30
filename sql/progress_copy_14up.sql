SELECT
  p.pid,
  now() - a.xact_start AS duration,
  coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
  --p.datname AS database,
  c.relnamespace::regnamespace || '.' || c.relname AS table,
  command,
  type,
  lpad(pg_size_pretty(bytes_total), 11)                                                                    AS "Size total",
  lpad(pg_size_pretty(bytes_processed), 11)                                                                AS "Size copied",
  trunc(bytes_processed::numeric * 100     / nullif(bytes_total,0)::numeric, 1)                  AS "% Copied",
  reltuples                                                                                      AS "Rows Total",
  trunc((tuples_processed::numeric * 100) / nullif(reltuples - tuples_excluded,0)::numeric,1)    AS "% Rows Copied",
  trunc(tuples_excluded::numeric * 100    / nullif(reltuples,0)::numeric)                        AS "% Rows excluded"
FROM
  pg_stat_progress_copy p
  JOIN pg_stat_activity a USING (pid)
  JOIN pg_class c ON c.oid = p.relid
ORDER BY now() - a.xact_start DESC;
