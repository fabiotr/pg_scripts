SELECT 
    row_number() over(order by temp_blks_read + temp_blks_written desc) "N", 
    queryid,
    datname AS "DB", 
    userid::regrole AS "User",  
    to_char((calls::numeric/reset_days::numeric),'9G999G990D9') AS "Calls/Day",
    to_char((rows/reset_days),'999G999G999') AS "Rows/Day",
    to_char((rows::numeric/calls::numeric),'999G990D9') AS "Rows/Call",
    --pg_size_pretty(temp_blks_read * current_setting('block_size')::integer) tot_temp_r, --pg_size_pretty(temp_blks_written * current_setting('block_size')::integer)tot_temp_w,
    pg_size_pretty(((temp_blks_read + temp_blks_written)/reset_days) * current_setting('block_size')::integer) AS "Temp/Day",
    pg_size_pretty((temp_blks_read + temp_blks_written) * current_setting('block_size')::integer / calls) avg_temp,
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE 
        THEN ((temp_blk_read_time + temp_blk_write_time)/reset_days) * INTERVAL '1 millisecond'
        ELSE NULL END AS "Temp time/Day",
    trunc(total_exec_time/(1000 * reset_days)) * INTERVAL '1 millisecond' AS "Time/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') || 
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE datname = current_database()
AND ((temp_blks_read + temp_blks_written) * current_setting('block_size')::integer) > 500000 --500 KB
ORDER BY temp_blks_read + temp_blks_written DESC
LIMIT 10;
