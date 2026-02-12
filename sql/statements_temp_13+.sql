SELECT 
    row_number() over(order by temp_blks_read + temp_blks_written desc) "N", 
    queryid,
    --datname db, 
    userid::regrole,  calls, 
    --pg_size_pretty(temp_blks_read * current_setting('block_size')::integer) tot_temp_r, --pg_size_pretty(temp_blks_written * current_setting('block_size')::integer)tot_temp_w,
    pg_size_pretty((temp_blks_read + temp_blks_written) * current_setting('block_size')::integer) total_temp,
    pg_size_pretty((temp_blks_read + temp_blks_written) * current_setting('block_size')::integer / calls) avg_temp,
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE 
        THEN (blk_read_time + blk_write_time) * INTERVAL '1 millisecond'
        ELSE NULL END AS "I/O Time",
    trunc(total_exec_time/1000) total_time_s,
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') || 
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid 
WHERE datname = current_database()
AND ((temp_blks_read + temp_blks_written) * current_setting('block_size')::integer) > 500000 --500 KB
ORDER BY temp_blks_read + temp_blks_written DESC
LIMIT 20;
