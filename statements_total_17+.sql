SELECT
    trim(to_char(count(1),'999G999')) || ' - ' || 
    trim(to_char(current_setting('pg_stat_statements.max')::integer,'9999G999')) || ' - ' || 
    trim(to_char(r.dealloc,'999G999')) AS "Queries (Tracked - Max - Lost)",
    to_char((sum(total_plan_time) / reset_days) * INTERVAL '1 millisecond' / (sum(calls)/reset_days),'SS.FF6') || ' - ' ||  
    to_char((sum(total_exec_time) / reset_days) * INTERVAL '1 millisecond' / (sum(calls)/reset_days),'SS.FF6') AS "Avg (Plan - Exec) time ", 
    trim(to_char(sum(calls)::numeric / reset_days,'999G999G999G999'))  || ' - ' ||
    trim(to_char(sum(rows)::numeric  / reset_days,'999G999G999G999'))  AS "(Calls - Rows)/Day",
    trim(to_char(sum(rows)::numeric / sum(calls)::numeric, '999G999D0')) AS "Rows/Call",
    CASE WHEN current_setting('pg_stat_statements.track') = 'all' 
	THEN trim(to_char(count(1) FILTER (WHERE toplevel = FALSE) / reset_days,'999G999G999'))  ELSE 'Disabled' END AS "Non Toplevel calls/Day", 
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char((sum(shared_blk_read_time + shared_blk_write_time) / reset_days) * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE 'Disabled' END || ' - ' || 
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char((sum(local_blk_read_time + local_blk_write_time)   / reset_days) * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE 'Disabled' END || ' - ' || 
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char((sum(temp_blk_read_time + temp_blk_write_time)     / reset_days) * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE 'Disabled' END AS "(Shared - Local - Temp) time/Day",
    to_char((sum(total_plan_time)                   / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') || ' - ' || 
    to_char((sum(total_exec_time)                   / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') || ' - ' || 
    to_char((sum(total_plan_time + total_exec_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "(Plan - Exec - Total) time/Day",
    trunc(sum(total_plan_time)::numeric * 100 / sum(total_plan_time + total_exec_time)::numeric,1) || ' %' AS "Plan time %",
    pg_size_pretty(trunc(((sum(shared_blks_hit))     / reset_days) * current_setting('block_size')::integer)) || ' - ' ||
    pg_size_pretty(trunc(((sum(shared_blks_read))    / reset_days) * current_setting('block_size')::integer)) || ' - ' || 
    pg_size_pretty(trunc(((sum(shared_blks_written)) / reset_days) * current_setting('block_size')::integer)) || ' - ' ||
    pg_size_pretty(trunc(((sum(shared_blks_dirtied)) / reset_days) * current_setting('block_size')::integer)) AS "Shared (Hit - Read - Write - Dirty)/Day",
    trunc(sum(shared_blks_hit) * 100 / sum(shared_blks_hit + shared_blks_read),1) || ' %' AS "Shared Hit",
    pg_size_pretty((nullif((sum(local_blks_read + local_blks_written))::numeric,0) / reset_days) * current_setting('block_size')::integer) || ' - ' ||
    pg_size_pretty((nullif((sum(temp_blks_read  + temp_blks_written))::numeric,0)  / reset_days) * current_setting('block_size')::integer) AS "(Local - Temp)/Day",
    to_char(current_timestamp - stats_reset, 'DD HH24:MI') || ' - ' || 
    to_char(stats_reset, 'YYYY-MM-DD HH24:MI') AS "Time since reset - Stats Reset"
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT dealloc, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days, stats_reset FROM pg_stat_statements_info) AS r
WHERE datname = current_database()
GROUP BY r.reset_days, r.stats_reset, r.dealloc;
