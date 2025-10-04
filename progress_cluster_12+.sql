SELECT
    --p.datname AS "DB", 
    p.pid,
    now() - a.xact_start AS duration,
    coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
    c.relnamespace::regnamespace || '.' || c.relname AS table,
    command,
    phase,
    c.reltuples AS "Total tuples",
    trunc(heap_tuples_scanned::numeric * 100 / reltuples::numeric,1) AS "% Rows scanned",
    trunc(heap_tuples_written::numeric * 100 / reltuples::numeric,1) AS "% Rows written",
    pg_size_pretty(heap_blks_total   * current_setting('block_size')::int) AS "Total Bytes",
    pg_size_pretty(heap_blks_scanned * current_setting('block_size')::int) AS "Scanned Bytes",
    (SELECT count(1) FROM pg_index AS i WHERE i.indexrelid = relid)        AS "Total indexes",
    index_rebuild_count                                                    AS "Rebuilted indexes"
FROM  
    pg_stat_progress_cluster AS p
    JOIN pg_stat_activity AS a using (pid)
    JOIN pg_class AS c ON c.oid = p.relid
ORDER BY now() - a.xact_start DESC;
