SELECT 
    row_number() over(order by sum(temp_blks_read + temp_blks_written) desc) "N",
    string_agg(distinct datname,',') db,
    string_agg(distinct rolname,', ') role,
    queryid, 
    trunc(sum(calls/reset_days),1) AS "Calls/Day", 
    pg_size_pretty(trunc((sum(temp_blks_read+ temp_blks_written)/reset_days) * current_setting('block_size')::integer)) AS "Temp/Day",
    pg_size_pretty(trunc((sum(temp_blks_read) + sum(temp_blks_written)) * current_setting('block_size')::integer / sum(calls))) avg_temp,
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE 
        THEN (sum(blk_read_time + blk_write_time)/reset_days) * INTERVAL '1 millisecond'
        ELSE NULL END AS "Temp Time/Day",
    trunc(sum(total_exec_time)/1000) total_exec_time_s,
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') 
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid
    JOIN pg_roles u ON u.oid = s.userid,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
GROUP BY reset_days, array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' '), queryid 
ORDER BY sum(temp_blks_read + temp_blks_written) DESC
LIMIT 20;
