SELECT
    lpad(CASE WHEN toplevel = FALSE THEN '* ' ELSE '' END || row_number() OVER (ORDER BY (total_exec_time + total_plan_time)/reset_days DESC),4)    AS "N",
    lpad(to_char(((total_exec_time + total_plan_time)/reset_days) * 100 / sum((total_exec_time + total_plan_time)/reset_days) OVER (),'FM90D00'),5) AS "Load %",
    userid::regrole AS "User",
    queryid AS "Query ID",
    lpad(to_char((calls::numeric/reset_days::numeric),'FM999G999G990D0'),13) AS "Calls/Day",
    lpad(to_char((rows::numeric/calls::numeric),          'FM999G990D0'), 9) AS "Rows/Call",
    lpad(to_char((plans::numeric/reset_days::numeric),'FM999G999G990D0'),13) AS "Plans/Day",
    to_char((total_exec_time::numeric/reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')           AS "Exec/Day",
    to_char((total_plan_time::numeric/reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')           AS "Plan/Day",
    trunc(total_plan_time::numeric * 100 / (total_plan_time + total_exec_time)::numeric, 1)           AS "Plan %",
    trunc(shared_blks_hit::numeric * 100 / nullif((shared_blks_hit + shared_blks_read),0)::numeric,1) AS "Hit %" ,
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_read::numeric)                   / reset_days),0)),7) AS "Read/Day",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * temp_blks_read + temp_blks_written)::numeric / reset_days),0)),7) AS "Temp/Day",
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE AND (blk_read_time + blk_write_time > 0)
        THEN ((blk_read_time + blk_write_time)/reset_days) * INTERVAL '1 millisecond'
        ELSE NULL END AS "I/O Time/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE 
    datname = current_database() AND
    total_exec_time + total_plan_time > 0 AND
    calls > 0
ORDER BY total_exec_time + total_plan_time DESC
LIMIT 20;
