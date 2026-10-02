SELECT 
    row_number() over(ORDER BY total_time DESC) "N", 
    lpad(to_char(total_time*100/sum(total_time) OVER (),'FM99D09'), 6) || '%' AS "load_%",
    array_to_string(regexp_split_to_array(query,E'\\s+'),' ') AS query
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid
WHERE datname = current_database()ORDER BY total_time DESC
LIMIT 5;
