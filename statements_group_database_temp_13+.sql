SELECT 
    -- string_agg(datname,',') db,
    row_number() over(order by sum(temp_blks_read + temp_blks_written) desc) "N",
    queryid, 
    sum(calls) AS calls, 
    pg_size_pretty((sum(temp_blks_read) + sum(temp_blks_written)) * current_setting('block_size')::integer) total_temp,
    pg_size_pretty((sum(temp_blks_read) + sum(temp_blks_written)) * current_setting('block_size')::integer / sum(calls)) avg_temp,
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE 
        THEN (sum(blk_read_time) + sum(blk_write_time)) * INTERVAL '1 millisecond'
        ELSE NULL END tot_temp_time,
    trunc(sum(total_exec_time)/1000) total_exec_time_s,
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') 
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid 
GROUP BY array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' '), queryid 
ORDER BY sum(temp_blks_read + temp_blks_written) DESC
LIMIT 20;
