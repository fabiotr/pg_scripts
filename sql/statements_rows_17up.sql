SELECT
    lpad(row_number() OVER (ORDER BY rows DESC)::text, 2) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '  ' END AS "N",
    lpad(to_char(rows*100/sum(rows) OVER (),'FM99D00'), 6) || '%' AS "Rows_%",
    --datname AS "DB", 
    userid::regrole AS "User",
    queryid,
    lpad(to_char(calls::numeric / since_days::numeric,'FM999G999G990D0'), 14) AS "Calls/Day",
    lpad(to_char(rows::numeric  / since_days::numeric,'FM9G999G999G990'), 14) AS "Rows/Day", 
    lpad(to_char(rows::numeric/calls::numeric,'FM999G990D0'), 10) AS "Rows/Call",
    to_char(((total_exec_time + total_plan_time) / since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total Time/Day",
    CASE WHEN stats_since - stats_reset < (CURRENT_TIMESTAMP - stats_reset) / 50
        THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END AS "Stats",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    (SELECT *, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_since)::numeric/(60*60*24) AS since_days FROM pg_stat_statements) AS s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE datname = current_database()
ORDER BY rows  DESC
LIMIT 10;
