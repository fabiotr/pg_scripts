\set QUIET on
\timing off
SELECT 
	schemaname AS "Schema",
	relname AS "Table",  
	to_char(n_tup_upd,'FM999G999G999G999') AS "UPDATEs"
FROM pg_stat_all_tables
ORDER BY n_tup_upd desc
LIMIT 10;
