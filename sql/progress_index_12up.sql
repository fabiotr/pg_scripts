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
  pg_size_pretty(blocks_total * current_setting('block_size')::int) || ' / ' ||
    pg_size_pretty(blocks_done  * current_setting('block_size')::int) || ' / ' ||   
    trunc(blocks_done::numeric * 100 / nullif(blocks_total::numeric,0),1) 
    AS "Size (Total/Done/% Done)",
  tuples_total || ' / ' ||
    trunc(tuples_done::numeric * 100 / nullif(tuples_total::numeric,0),1) 
    AS "Rows (Total/% Done)",
  partitions_total || ' / ' || partitions_done AS "Partitions (Total/Done)"
FROM
  pg_stat_progress_create_index p
  JOIN pg_stat_activity a using (pid)
  JOIN pg_class c ON c.oid = p.relid
  LEFT JOIN pg_class ci ON ci.oid = p.index_relid
ORDER BY now() - a.xact_start DESC;
