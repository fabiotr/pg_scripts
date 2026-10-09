SELECT 
    row_number() over(ORDER BY total_time DESC) "N", 
    lpad(to_char(total_time*100/ nullif(sum(total_time) OVER (), 0),'FM99D09'), 6) || '%' AS "load_%",
    queryid id, 
    array_to_string(regexp_split_to_array(query,E'\\s+'),' ') AS query
FROM 
    :svp_pgss.pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
WHERE datname = current_database()
ORDER BY total_time DESC
LIMIT 5;
