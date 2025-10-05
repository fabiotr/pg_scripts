\set QUIET on
\timing off
SELECT 
	schemaname AS "Schema",
	relname AS "Table",  
	to_char(n_tup_del,'999G999G999G999') AS "DELETEs"
FROM pg_stat_user_tables
ORDER BY n_tup_del desc
LIMIT 10;

