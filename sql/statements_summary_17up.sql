SELECT
    lpad(CASE WHEN toplevel = FALSE THEN '* ' ELSE '' END || row_number() OVER (ORDER BY (total_exec_time + total_plan_time)/since_days DESC),4)    AS "N",
    lpad(to_char(((total_exec_time + total_plan_time)/since_days) * 100 / sum((total_exec_time + total_plan_time)/since_days) OVER (),'FM90D00'),5) AS "Load %",
    userid::regrole AS "User",
    queryid AS "Query ID",
    lpad(to_char((calls::numeric/since_days::numeric),'FM999G999G990D0'),13) AS "Calls/Day",
    lpad(to_char((plans::numeric/since_days::numeric),'FM999G999G990D0'),13) AS "Plans/Day",
    lpad(to_char((rows::numeric/calls::numeric),          'FM999G990D0'), 9) AS "Rows/Call",
    to_char((total_exec_time::numeric/since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')           AS "Exec/Day",
    to_char((total_plan_time::numeric/since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')           AS "Plan/Day",
    trunc(total_plan_time::numeric * 100 / (total_plan_time + total_exec_time)::numeric, 1)           AS "Plan %",
    trunc(shared_blks_hit::numeric * 100 / nullif((shared_blks_hit + shared_blks_read),0)::numeric,1) AS "Hit %" ,
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_read::numeric)                   / since_days),0)),7) AS "Read/Day",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * temp_blks_read + temp_blks_written)::numeric / since_days),0)),7) AS "Temp/Day",
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char(((temp_blk_read_time + temp_blk_write_time)/since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')
        ELSE NULL END AS "I/O Time/Day",
    CASE WHEN stats_since - stats_reset < (current_timestamp - stats_reset) / 50
	THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END        AS "Stats",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END                  AS query
FROM
    (SELECT *, EXTRACT(EPOCH FROM current_timestamp - stats_since)::numeric/(60*60*24) AS since_days FROM pg_stat_statements) AS s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE
    datname = current_database() AND
    total_exec_time + total_plan_time > 0 AND
    calls > 0
ORDER BY (total_exec_time + total_plan_time) / since_days DESC
LIMIT 20;
