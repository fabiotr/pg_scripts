SELECT
  p.pid,
  now() - a.xact_start AS duration,
  coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
  lockers_total,
  lockers_done,
  current_locker_pid,
  c.relnamespace::regnamespace || '.' || c.relname AS table,
  command,
  phase,
  pg_size_pretty(blocks_total * current_setting('block_size')::int) AS "Size total",
  pg_size_pretty(blocks_done  * current_setting('block_size')::int) AS "Size done",
  trunc(blocks_done::numeric * 100 / blocks_total::numeric, 1)        AS "% Done",
  tuples_total                                                      AS "Rows Total",
  trunc(tuples_done::numeric * 100 / tuples_total::numeric,1)       AS "% Rows Done",
  partitions_total                                                  AS "Partitions Total",
  partitions_done                                                   AS "Partitions Done"
FROM
  pg_stat_progress_create_index p
  JOIN pg_stat_activity a using (pid)
  JOIN pg_class c ON c.oid = p.relid
ORDER BY now() - a.xact_start DESC;
