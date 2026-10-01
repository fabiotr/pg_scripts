SELECT
    schemaname AS "Schema",
    funcname   AS "Function",
    lpad(to_char(calls, 'FM999G999G999G999'), 16) AS "Calls",
    to_char(total_time * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS "Total",
    to_char(self_time  * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS "Self",
    to_char(CASE calls WHEN 0 THEN 0 ELSE  trunc(self_time/calls) END * INTERVAL '1 millisecond', 'HH24:MI:SS,US')  "Average"
FROM pg_stat_user_functions
ORDER BY self_time DESC
LIMIT 20;
