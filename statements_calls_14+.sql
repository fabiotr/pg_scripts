SELECT
    row_number() over(order by calls  desc) "N",
    trim(to_char(calls*100/sum(calls) OVER (),'99D99') || '%') AS "Calls_%",
    datname AS "DB", userid::regrole AS "User",
    queryid,
    to_char(calls/reset_days,'999G999G999') AS "Calls/Day",
    to_char((rows/reset_days),'999G999G999') AS "Rows/Day",
    to_char(rows::numeric/calls::numeric,'999G990D9') AS "Rows/Call",
    to_char(min_exec_time                * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max_exec_time                * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(mean_exec_time               * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char((total_exec_time/reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE datname = current_database()
ORDER BY calls DESC
LIMIT 10;
