SELECT
    row_number() over(ORDER BY total_time DESC) "N",
    lpad(to_char(total_time*100/sum(total_time) OVER (),'FM99D09'), 6) || '%' AS "load_%",
    queryid,
    array_to_string(regexp_split_to_array(substr(query,1,5000),E'\\s+'),' ') AS query
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
--    JOIN pg_authid u ON u.oid = s.userid
WHERE datname = current_database()
ORDER BY total_time DESC
LIMIT 5;
