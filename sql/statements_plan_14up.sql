SELECT
    lpad(row_number() OVER (ORDER BY total_plan_time DESC)::text, 2)  || CASE WHEN toplevel = FALSE THEN ' *' ELSE '  ' END AS "N",
    lpad(to_char(total_plan_time*100/ nullif(sum(total_plan_time) OVER (), 0),'FM09D09'), 6) || '%' AS "load_%",
    --datname AS "DB", 
    userid::regrole AS "User",
    queryid,
    --to_char((rows::numeric/calls::numeric),          'FM999G990D0') AS "Rows/Call",
    --to_char((rows::numeric/reset_days::numeric),   'FM999G999G999') AS "Rows/Day",
    --to_char((plans::numeric/reset_days::numeric),  'FM999G999G999') AS "Plans/Day",
    lpad(to_char((calls::numeric/reset_days::numeric),'FM999G999G990D0'), 14) AS "Calls/Day",
    lpad(to_char((calls::numeric/plans::numeric),         'FM999G990D0'), 10) AS "Calls/Plan",
    to_char(min_plan_time                * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max_plan_time                * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(mean_plan_time               * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char(stddev_plan_time             * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS "σ",
    to_char((total_plan_time/reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')    AS "Plan/Day",
    to_char((total_exec_time/reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')    AS "Exec/Day",
    lpad(to_char(total_plan_time * 100 / (total_plan_time + total_exec_time),'FM09D09'), 6) || '%' AS "Plan %",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    :svp_pgss.pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM :svp_pgss.pg_stat_statements_info) AS r
WHERE 
    total_plan_time > 0 AND
    datname = current_database()
ORDER BY total_plan_time DESC
LIMIT 10;
