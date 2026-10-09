SELECT
    count(1)                                  AS "Tracked queries",
    current_setting('pg_stat_statements.max') AS "Max",
    r.dealloc                                 AS "Lost",
    to_char((sum(total_plan_time) / reset_days) * INTERVAL '1 millisecond' / (sum(calls)/reset_days),'SS.FF6') || ' - ' ||
    to_char((sum(total_exec_time) / reset_days) * INTERVAL '1 millisecond' / (sum(calls)/reset_days),'SS.FF6')       AS "Avg (Plan - Exec) time ",
    lpad(to_char(sum(calls)::numeric / reset_days,'FM999G999G999G999'), 16)  || ' - ' ||
    lpad(to_char(sum(rows)::numeric  / reset_days,'FM999G999G999G999'), 16)                                          AS "(Calls - Rows)/Day",
    lpad(to_char(sum(rows)::numeric / nullif(sum(calls),0)::numeric, 'FM999G990D0'), 10)                                       AS "Rows/Call",
    lpad(CASE WHEN current_setting('pg_stat_statements.track') = 'all'
        THEN to_char(count(1) FILTER (WHERE toplevel = FALSE) / reset_days,'FM999G999G999')  ELSE 'Disabled' END, 12)     AS "Non Toplevel calls/Day",
    lpad(to_char(sum(wal_records)  / reset_days, 'FM999G999G999'), 12) || ' - ' ||
    lpad(pg_size_pretty(trunc(sum(wal_bytes)/ reset_days)), 11)                                                                AS "WAL (Records - Size)/Day",
    lpad(to_char(sum(wal_records)  / nullif(sum(calls),0)::numeric, 'FM999G990D0'), 10)                                        AS "Wal/Call",
    to_char((sum(total_plan_time)                   / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') || ' - ' ||
    to_char((sum(total_exec_time)                   / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') || ' - ' ||
    to_char((sum(total_plan_time + total_exec_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')          AS "(Plan - Exec - Total) time/Day",
    lpad(trunc(sum(total_plan_time)::numeric * 100 / nullif(sum(total_plan_time + total_exec_time),0)::numeric,1) || ' %', 7) AS "Plan time %",
    lpad(pg_size_pretty(trunc(((sum(shared_blks_hit))     / reset_days) * current_setting('block_size')::integer)), 11) || ' - ' ||
    lpad(pg_size_pretty(trunc(((sum(shared_blks_read))    / reset_days) * current_setting('block_size')::integer)), 11) || ' - ' ||
    lpad(pg_size_pretty(trunc(((sum(shared_blks_written)) / reset_days) * current_setting('block_size')::integer)), 11) || ' - ' ||
    lpad(pg_size_pretty(trunc(((sum(shared_blks_dirtied)) / reset_days) * current_setting('block_size')::integer)), 11)        AS "Shared (Hit - Read - Write - Dirty)/Day",
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char((sum(shared_blk_read_time + shared_blk_write_time) / reset_days)
            * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE 'Disabled' END                                                                                          AS "Shared T/Day",
    lpad(trunc(sum(shared_blks_hit) * 100 / nullif(sum(shared_blks_hit + shared_blks_read),0)::numeric,1) || ' %', 7)         AS "Shared Hit",
    lpad(pg_size_pretty((nullif((sum(local_blks_read + local_blks_written))::numeric,0) / reset_days) * current_setting('block_size')::integer), 11) || ' - ' ||
    lpad(pg_size_pretty((nullif((sum(temp_blks_read  + temp_blks_written))::numeric,0)  / reset_days) * current_setting('block_size')::integer), 11) AS "(Local - Temp)/Day",
    to_char(CURRENT_TIMESTAMP - stats_reset, 'DD HH24:MI')                                                           AS "Time since reset",
    to_char(stats_reset, 'YYYY-MM-DD HH24:MI')                                                                       AS "Stats Reset"
FROM
    :svp_pgss.pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT dealloc, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days, stats_reset FROM :svp_pgss.pg_stat_statements_info) AS r
GROUP BY r.reset_days, r.stats_reset,r.dealloc;
