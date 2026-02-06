SELECT 
    row_number() over(order by total_exec_time desc) "N", 
    trim(to_char((total_exec_time + total_plan_time) * 100/sum(total_exec_time + total_plan_time) OVER (),'99D99') || '%') AS "load_%",
    queryid id, 
    array_to_string(regexp_split_to_array(query,'\s+'),' ') AS query
FROM 
    pg_stat_statements s
WHERE datname = current_database()
ORDER BY total_exec_time + total_plan_time DESC
LIMIT 5;
