SELECT
    row_number() over(ORDER BY calls  DESC) "N",
    lpad(to_char(calls*100/ nullif(sum(calls) OVER (), 0),'FM99D09'), 6) || '%' AS "Calls_%",
    --datname AS "DB", 
    userid::regrole AS "User",
    queryid,
    lpad(to_char(calls/reset_days,'FM999G999G999'), 12) AS "Calls/Day",
    lpad(to_char((rows/reset_days),'FM999G999G999'), 12) AS "Rows/Day",
    lpad(to_char(rows::numeric/calls::numeric,'FM999G990D0'), 10) AS "Rows/Call",
    to_char(min_exec_time                * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max_exec_time                * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(mean_exec_time               * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char((total_exec_time/reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    :svp_pgss.pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM :svp_pgss.pg_stat_statements_info) AS r
WHERE datname = current_database()
ORDER BY calls DESC
LIMIT 10;
