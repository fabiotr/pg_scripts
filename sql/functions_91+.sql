SELECT
    schemaname AS "Schema",
    funcname   AS "Function",
    to_char((calls/reset_days), '999G999G999G999') AS "Calls/Day",
    to_char((total_time/reset_days)  * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS "Total/Day",
    to_char((self_time/reset_days)  * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS "Self/Day",
    to_char(CASE calls WHEN 0 THEN 0 ELSE  TRUNC(self_time/calls) END * INTERVAL '1 millisecond', 'HH24:MI:SS,US')  "Average"
FROM 
	pg_stat_user_functions
	 JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
ORDER BY self_time desc
LIMIT 20;
