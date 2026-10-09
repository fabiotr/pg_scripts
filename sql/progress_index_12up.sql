-- Temporary files per backend, from every tablespace. pg_ls_tmpdir() lists only
-- the files at the top of pgsql_tmp: the shared filesets of parallel builds live
-- in subdirectories, so a parallel build shows no temporary files.
WITH tmp AS (
\if :svp_ls_tmpdir
  SELECT
    substring(f.name FROM '^pgsql_tmp([0-9]+)[.]')::int AS pid,
    count(1)    AS files,
    sum(f.size) AS bytes
  FROM
    pg_tablespace t,
    pg_ls_tmpdir(t.oid) f
  WHERE f.name ~ '^pgsql_tmp[0-9]+[.]'
  GROUP BY 1
\else
  SELECT NULL::int AS pid, NULL::bigint AS files, NULL::numeric AS bytes
\endif
)
SELECT
  p.pid,
  now() - a.xact_start AS duration,
  coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
  lockers_total || ' / ' ||  
    lockers_done || ' / ' || 
    current_locker_pid AS "Lockers (Total/Done/C. PID)",
  c.relnamespace::regnamespace || '.' || c.relname AS table,
  ci.relname AS index,
  command,
  phase,
  CASE WHEN :'svp_ls_tmpdir'::boolean
    THEN coalesce(tmp.files, 0) || ' / ' || lpad(pg_size_pretty(coalesce(tmp.bytes, 0)), 11)
    ELSE 'needs pg_monitor' END AS "Temp files (Qty/Size)",
  lpad(pg_size_pretty(blocks_total * current_setting('block_size')::int), 11) || ' / ' ||
    lpad(pg_size_pretty(blocks_done  * current_setting('block_size')::int), 11) || ' / ' ||   
    trunc(blocks_done::numeric * 100 / nullif(blocks_total::numeric,0),1) 
    AS "Size (Total/Done/% Done)",
  tuples_total || ' / ' ||
    trunc(tuples_done::numeric * 100 / nullif(tuples_total::numeric,0),1) 
    AS "Rows (Total/% Done)",
  partitions_total || ' / ' || partitions_done AS "Partitions (Total/Done)"
FROM
  pg_stat_progress_create_index p
  JOIN pg_stat_activity a USING (pid)
  LEFT JOIN tmp ON tmp.pid = p.pid
  JOIN pg_class c ON c.oid = p.relid
  LEFT JOIN pg_class ci ON ci.oid = p.index_relid
ORDER BY now() - a.xact_start DESC;
