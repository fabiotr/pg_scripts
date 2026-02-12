SELECT 
    row_number() over(order by sum(total_exec_time) desc) "N",
    string_agg(distinct datname,', ') db,
    string_agg(distinct rolname,', ') role,
    queryid,
    to_char(sum(calls/reset_days),'999G999G999') AS "Calls/Day", 
    to_char(min(min_exec_time)              * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max(max_exec_time)              * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(avg(mean_exec_time)             * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char(sum(total_exec_time/reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ')
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid 
    JOIN pg_roles u ON u.oid = s.userid,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
GROUP BY queryid, array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ')
ORDER BY sum(total_exec_time) DESC
LIMIT 20;
