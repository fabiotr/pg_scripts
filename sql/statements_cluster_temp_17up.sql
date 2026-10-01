SELECT 
    row_number() over(ORDER BY sum(temp_blks_read + temp_blks_written) DESC) "N",
    string_agg(DISTINCT datname,',') db,
    string_agg(DISTINCT rolname,', ') role,
    queryid, 
    trunc(sum(calls/reset_days),1) AS "Calls/Day", 
    lpad(pg_size_pretty(trunc((sum(temp_blks_read+ temp_blks_written)/reset_days) * current_setting('block_size')::integer)), 11) AS "Temp/Day",
    lpad(pg_size_pretty(trunc((sum(temp_blks_read) + sum(temp_blks_written)) * current_setting('block_size')::integer / sum(calls)::numeric)), 11) avg_temp,
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE 
        THEN to_char((sum(temp_blk_read_time + temp_blk_write_time)/reset_days) * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE NULL END AS "Temp Time/Day",
    to_char((sum(total_exec_time + total_plan_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS total_time,
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') AS "Query"
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid
    JOIN pg_roles u ON u.oid = s.userid,
    (SELECT EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
GROUP BY reset_days, array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' '), queryid 
HAVING sum(calls) > 0 AND sum(temp_blks_read) + sum(temp_blks_written) > 0
ORDER BY sum(temp_blks_read + temp_blks_written) DESC
LIMIT 20;
