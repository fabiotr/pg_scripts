SELECT
    lpad(row_number() OVER (ORDER BY total_exec_time DESC)::text, 2)  || CASE WHEN toplevel = FALSE THEN ' *' ELSE '  ' END AS "N",
    lpad(to_char(total_exec_time*100/sum(total_exec_time) OVER (),'FM90D00'), 6) || '%' AS "load_%",
    --datname AS "DB", 
    userid::regrole AS "User",
    queryid,
    lpad(to_char((calls::numeric/since_days::numeric),'FM999G999G990D0'), 14) AS "Calls/Day",
    --to_char((rows::numeric/since_days::numeric),   'FM999G999G999') AS "Rows/Day",
    --to_char((rows::numeric/calls::numeric),          'FM999G990D0') AS "Rows/Call",
    to_char(min_exec_time                * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max_exec_time                * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(mean_exec_time               * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char(stddev_exec_time             * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS "σ",
    to_char((total_exec_time::numeric/since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Exec/Day",
    to_char((total_plan_time::numeric/since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Plan/Day",
    CASE WHEN stats_since = minmax_stats_since
        THEN NULL ELSE to_char(minmax_stats_since, 'YYYY-MM-DD HH24:MI') END AS "MinMax",
    CASE WHEN stats_since - stats_reset < (CURRENT_TIMESTAMP - stats_reset) / 50
        THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END        AS "Stats",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END                  AS query
FROM
    (SELECT *, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_since)::numeric/(60*60*24) AS since_days FROM :svp_pgss.pg_stat_statements) AS s
    JOIN pg_database AS d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM :svp_pgss.pg_stat_statements_info) AS r
WHERE datname = current_database()
ORDER BY total_exec_time DESC
LIMIT 10;
