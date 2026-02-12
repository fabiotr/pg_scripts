\set QUIET on
\t on
\timing off
--\x on
SELECT 	'Time since last Reset: ' || to_char(current_timestamp - stats_reset, 'DD-MM-YY hh24:mi') AS "Time since last Reset:"  --, stats_reset
FROM pg_stat_database WHERE datname = current_database();
\t off
--\x off
SELECT 
	schemaname AS "Schema",
	relname AS "Table",  
	to_char(n_tup_del / reset_days,'999G999G999G999') AS "DELETEs/Day"
FROM
    pg_stat_user_tables,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days 
    	FROM pg_stat_database 
    	WHERE datname = current_database()) AS r
ORDER BY n_tup_del desc
LIMIT 10;

