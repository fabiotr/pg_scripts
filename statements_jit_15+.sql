SELECT
    row_number() OVER (ORDER BY jit_emission_time + jit_optimization_time + jit_inlining_time + jit_generation_time DESC) || 
        CASE WHEN toplevel = FALSE THEN ' *' ELSE '' END AS "N",
    trim(to_char((jit_emission_time + jit_optimization_time + jit_inlining_time + jit_generation_time) * 100 / 
    sum(jit_emission_time + jit_optimization_time + jit_inlining_time + jit_generation_time) OVER (),'99D99') || '%') AS "Jit %",
    --datname AS "DB",
    userid::regrole AS "User",
    queryid,
    to_char(calls::numeric                  / reset_days::numeric, '999G999G990D9') AS "Calls/Day",
    to_char(jit_functions::numeric          / calls::numeric,      '999G999G990D9') AS "Jit/Call",
    to_char(jit_functions::numeric          / reset_days::numeric, '999G999G990D9') AS "Jit/Day",
    to_char(jit_inlining_count::numeric     / reset_days::numeric, '999G999G990D9') AS "Inlinings/Day",
    to_char(jit_optimization_count::numeric / reset_days::numeric, '999G999G990D9') AS "Optimizations/Day",
    to_char(jit_emission_count::numeric     / reset_days::numeric, '999G999G990D9') AS "Emissions/Day",
    to_char((total_exec_time + total_plan_time / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Query Time/Day",
    to_char((jit_generation_time               / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Generation/Day",
    to_char((jit_inlining_time                 / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Inlining/Day",
    to_char((jit_optimization_time             / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Optimization/Day",
    to_char((jit_emission_time                 / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Emission/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    pg_stat_statements AS s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE
    jit_functions > 0 AND
    datname = current_database()
ORDER BY jit_emission_time + jit_optimization_time + jit_inlining_time + jit_generation_time DESC
LIMIT 10;
