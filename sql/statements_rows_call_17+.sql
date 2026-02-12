SELECT
    row_number() OVER (ORDER BY rows / calls DESC) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '' END AS "N",
    --datname AS "DB", 
    userid::regrole AS "User",
    queryid,
    to_char(calls/since_days,'999G999G999') AS "Calls/Day",
    to_char((rows/since_days),'999G999G999') AS "Rows/Day",
    to_char(rows/calls,'999G999') AS "Rows/Call",
    to_char(((total_exec_time + total_plan_time) / since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total Time/Day",
    CASE WHEN stats_since - stats_reset < (current_timestamp - stats_reset) / 50
        THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END AS "Stats",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    (SELECT *, EXTRACT(EPOCH FROM current_timestamp - stats_since)::numeric/(60*60*24) AS since_days FROM pg_stat_statements) AS s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE 
    datname = current_database() AND 
    calls > 0
ORDER BY rows/calls DESC
LIMIT 10;
