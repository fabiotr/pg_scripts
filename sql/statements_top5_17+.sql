SELECT 
    row_number() over(order by (total_exec_time + total_plan_time)/since_days DESC) "N", 
    trim(to_char(((total_exec_time + total_plan_time)/since_days) * 100/sum((total_exec_time + total_plan_time)/since_days) OVER (),'99D99') || '%') AS "load_%",
    queryid id, 
    CASE WHEN stats_since - stats_reset < (current_timestamp - stats_reset) / 50
        THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END AS "Stats",
    array_to_string(regexp_split_to_array(query,'\s+'),' ') AS query
FROM 
     (SELECT *, EXTRACT(EPOCH FROM current_timestamp - stats_since)::numeric/(60*60*24) AS since_days FROM pg_stat_statements) AS s
    JOIN pg_database AS d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE datname = current_database()
ORDER BY (total_exec_time + total_plan_time)/since_days DESC
LIMIT 5;
