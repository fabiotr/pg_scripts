SELECT 
    row_number() over(order by total_exec_time desc) "N", 
    trim(to_char(total_exec_time*100/sum(total_exec_time) OVER (),'99D99') || '%') AS "load_%",
    queryid id, 
    array_to_string(regexp_split_to_array(query,'\s+'),' ') AS query
FROM 
    pg_stat_statements s 
ORDER BY total_exec_time DESC
LIMIT 5;
