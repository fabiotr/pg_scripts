SELECT
    row_number() over(ORDER BY total_time DESC) "N",
    lpad(to_char(total_time*100/sum(total_time) OVER (),'FM99D09'), 6) || '%' AS "load_%",
    queryid,
    datname db,
    userid::regrole AS "User",
    lpad(to_char(calls,'FM999G999G999G999'), 16) AS calls,
    to_char(min_time   * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max_time   * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(mean_time  * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,  
    to_char(total_time * INTERVAL '1 millisecond', 'HH24:MI:SS')    AS total,
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    :svp_pgss.pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
WHERE datname = current_database()
ORDER BY total_time DESC
LIMIT 20;
