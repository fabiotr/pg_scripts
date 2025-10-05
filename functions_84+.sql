SELECT
    schemaname AS "Schema",
    funcname   AS "Function",
    to_char(calls, '999G999G999G999') AS "Calls",
    to_char(total_time * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS "Total",
    to_char(self_time  * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS "Self",
    to_char(CASE calls WHEN 0 THEN 0 ELSE  TRUNC(self_time/calls) END * INTERVAL '1 millisecond', 'HH24:MI:SS,US')  "Average"
FROM pg_stat_user_functions
ORDER BY self_time desc
LIMIT 20;
