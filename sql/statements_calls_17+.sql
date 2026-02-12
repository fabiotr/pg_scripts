SELECT
    row_number() over(order by calls  DESC) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '' END "N",
    trim(to_char(calls*100/sum(calls) OVER (),'99D99') || '%') AS "Calls_%",
    --datname AS "DB",
    userid::regrole AS "User",
    queryid,
    calls,
    to_char(calls::numeric/since_days,'999G999G999') AS "Calls/Day",
    to_char((rows/since_days),'999G999G999') AS "Rows/Day",
    to_char(rows::numeric/calls::numeric,'999G990D9') AS "Rows/Call",
    to_char((total_plan_time/since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Plan/Day",
    to_char((total_exec_time/since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Exec/Day",
    CASE WHEN stats_since - stats_reset < (current_timestamp - stats_reset) / 50
        THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END        AS "Stats",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    (SELECT *, EXTRACT(EPOCH FROM current_timestamp - stats_since)::numeric/(60*60*24) AS since_days FROM pg_stat_statements) AS s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE datname = current_database()
ORDER BY calls DESC
LIMIT 10;
