SELECT
    lpad(row_number() OVER (ORDER BY rows / calls DESC)::text, 2) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '  ' END AS "N",
    --datname AS "DB", 
    userid::regrole AS "User",
    queryid,
    lpad(to_char(calls/reset_days,'FM999G999G999'), 12) AS "Calls/Day",
    lpad(to_char((rows/reset_days),'FM999G999G999'), 12) AS "Rows/Day",
    lpad(to_char(rows/calls,'FM999G999'), 8) AS "Rows/Call",
    to_char(((total_exec_time + total_plan_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total Time/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE 
    datname = current_database() AND
    calls > 0
ORDER BY rows/calls DESC
LIMIT 10;
