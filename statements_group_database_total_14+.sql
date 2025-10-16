\x on
SELECT
    s.q || ' / ' || current_setting('pg_stat_statements.max') || ' / ' || r.dealloc AS "Number of queryes / Max / Lost",
    to_char(current_timestamp - stats_reset, 'YYYY-MM-DD HH24:MI') AS "Time since last Reset",
    to_char(stats_reset, 'YYYY-MM-DD HH24:MI') AS "Stats Reset"
FROM
 (SELECT count(1) AS q FROM pg_stat_statements) s,
 pg_stat_statements_info r
;

\x off
SELECT
    d.datname AS "Database",
    to_char(sum(total_plan_time) * INTERVAL '1 millisecond' / nullif(sum(calls),0),'SS.FF6')                     AS "Avg Plan T",
    to_char(sum(total_exec_time) * INTERVAL '1 millisecond' / nullif(sum(calls),0),'SS.FF6')                     AS "Avg Exec T",
    to_char((sum(total_plan_time) / reset_days) * INTERVAL '1 millisecond',                      'HH24:MI:SS') AS "Plan T/Day",
    to_char((sum(total_exec_time) / reset_days) * INTERVAL '1 millisecond',                      'HH24:MI:SS') AS "Exec T/Day",
    to_char((sum(total_plan_time + total_exec_time) / reset_days) * INTERVAL '1 millisecond',    'HH24:MI:SS') AS "Total T/Day",
    trunc(sum(total_plan_time)::numeric * 100 / nullif(sum(total_plan_time + total_exec_time)::numeric,0),1) || ' %' AS "Plan %",
    to_char(sum(calls)::numeric / reset_days,'999G999G999')                                                    AS "Calls/Day",
    CASE WHEN current_setting('pg_stat_statements.track') = 'all'
        THEN to_char(count(1) FILTER (WHERE toplevel = FALSE) / reset_days,'999G999G999')  ELSE 'Disabled' END AS "N TopLevel/Day",
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char((sum(blk_read_time + blk_write_time)     / reset_days)
            * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE 'Disabled' END                                                                                    AS "I/O T/Day",
    trunc(sum(shared_blks_hit) * 100 / nullif(sum(shared_blks_hit + shared_blks_read),0),1) || ' %'            AS "Shared Hit",
    pg_size_pretty(trunc((nullif((sum(shared_blks_hit))::numeric,0)     / reset_days) * current_setting('block_size')::integer)) AS "S Hit/Day",
    pg_size_pretty(trunc((nullif((sum(shared_blks_read))::numeric,0)    / reset_days) * current_setting('block_size')::integer)) AS "S Read/Day",
    pg_size_pretty(trunc((nullif((sum(shared_blks_written))::numeric,0) / reset_days) * current_setting('block_size')::integer)) AS "S Write/Day",
    pg_size_pretty(trunc((nullif((sum(shared_blks_dirtied))::numeric,0) / reset_days) * current_setting('block_size')::integer)) AS "S Dirty/Day",
    pg_size_pretty(trunc((nullif((sum(local_blks_read + local_blks_written))::numeric,0) / reset_days) * current_setting('block_size')::integer)) AS "Local/Day",
    pg_size_pretty(trunc((nullif((sum(temp_blks_read  + temp_blks_written))::numeric,0)  / reset_days) * current_setting('block_size')::integer)) AS "Temp/Day"
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT dealloc, nullif(EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24)::numeric,0) AS reset_days, stats_reset FROM pg_stat_statements_info) AS r
WHERE datname NOT IN ('template1', 'template0')
GROUP BY d.datname, r.reset_days, r.stats_reset, r.dealloc
ORDER BY 6 DESC;
