\set QUIET on
\timing off
SELECT 
	schemaname AS "Schema",
	relname AS "Table",  
	to_char(n_tup_ins,'999G999G999G999') AS "INSERTSs"
FROM pg_stat_user_tables
ORDER BY n_tup_ins desc
LIMIT 10;

