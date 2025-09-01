SELECT
    row_number() over(order by calls  desc) "N",
    trim(to_char(calls*100/sum(calls) OVER (),'99D99') || '%') AS "Calls_%",
    datname AS "DB", 
    rolname AS "User",
    queryid,
    to_char(calls,'999G999G999') AS "Calls",
    to_char((rows),'999G999G999') AS "Rows",
    to_char(rows/calls,'999G999') AS "Rows/Call",
    to_char((total_time / calls) * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char((total_time)         * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
    JOIN pg_roles r ON r.oid = s.userid
WHERE datname = current_database()
ORDER BY calls DESC
LIMIT 10;
