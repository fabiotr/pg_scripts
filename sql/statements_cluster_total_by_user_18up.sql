SELECT
    u.rolname AS "User",
    to_char(sum(total_plan_time) * INTERVAL '1 millisecond' / nullif(sum(calls),0),'SS.FF6')                  AS "Avg Plan T",
    to_char(sum(total_exec_time) * INTERVAL '1 millisecond' / nullif(sum(calls),0),'SS.FF6')                  AS "Avg Exec T",
    to_char((sum(total_plan_time)                   / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')   AS "Plan T/Day",
    to_char((sum(total_exec_time)                   / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')   AS "Exec T/Day",
    to_char((sum(total_plan_time + total_exec_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')   AS "Total T/Day",
    trunc(sum(total_plan_time)::numeric * 100 / sum(total_plan_time + total_exec_time)::numeric,1) || ' %'    AS "Plan %",
    lpad(to_char(sum(calls)::numeric / reset_days,'FM999G999G999'), 12)                                                   AS "Calls/Day",
    lpad(CASE WHEN current_setting('pg_stat_statements.track') = 'all'
	THEN to_char(count(1) FILTER (WHERE toplevel = FALSE) / reset_days,'FM999G999G999') ELSE 'Disabled' END, 12) AS "N TopLevel/Day",
    lpad(to_char((sum(parallel_workers_launched)::numeric/reset_days::numeric),  'FM999G999G999'), 12)                    AS "Workers L/Day",
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char((sum(shared_blk_read_time + shared_blk_write_time) / reset_days)
            * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE 'Disabled' END                                                                                   AS "Shared T/Day",
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char((sum(temp_blk_read_time + temp_blk_write_time)     / reset_days)
            * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE 'Disabled' END                                                                                   AS "Temp T/Day",
    trunc(sum(shared_blks_hit) * 100 / nullif(sum(shared_blks_hit + shared_blks_read),0),1) || ' %'           AS "Shared Hit",
    lpad(pg_size_pretty(trunc((nullif((sum(shared_blks_hit))::numeric,0)     / reset_days) * current_setting('block_size')::integer)), 11) AS "S Hit/Day",
    lpad(pg_size_pretty(trunc((nullif((sum(shared_blks_read))::numeric,0)    / reset_days) * current_setting('block_size')::integer)), 11) AS "S Read/Day",
    lpad(pg_size_pretty((trunc(nullif((sum(shared_blks_written))::numeric,0) / reset_days) * current_setting('block_size')::integer)), 11) AS "S Write/Day",
    lpad(pg_size_pretty(trunc((nullif((sum(shared_blks_dirtied))::numeric,0) / reset_days) * current_setting('block_size')::integer)), 11) AS "S Dirty/Day",
    lpad(pg_size_pretty(trunc((nullif((sum(local_blks_read + local_blks_written))::numeric,0) / reset_days) * current_setting('block_size')::integer)), 11) AS "Local/Day",
    lpad(pg_size_pretty(trunc((nullif((sum(temp_blks_read  + temp_blks_written))::numeric,0)  / reset_days) * current_setting('block_size')::integer)), 11) AS "Temp/Day"
FROM
    pg_stat_statements s
    JOIN pg_roles u ON u.oid = s.userid,
    (SELECT dealloc, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days, stats_reset FROM pg_stat_statements_info) AS r
GROUP BY u.rolname, r.reset_days, r.stats_reset, r.dealloc
ORDER BY 6 DESC;
