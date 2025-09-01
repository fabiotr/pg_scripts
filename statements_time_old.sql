SELECT
    row_number() over(order by total_time desc) "#",
trim(to_char(total_time*100/sum(total_time) OVER (),'99D99') || '%') AS "load_%",
    datname db,
    queryid,
    to_char(calls,'999G999G999G999') AS calls,
    to_char(min_time        * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max_time        * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(mean_time       * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char(total_time      * INTERVAL '1 millisecond', 'HH24:MI:SS') AS total,
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
WHERE datname = current_database()
ORDER BY total_time DESC
LIMIT 20;

