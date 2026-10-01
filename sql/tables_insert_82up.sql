SELECT 
	schemaname AS "Schema",
	relname AS "Table",  
	lpad(to_char(n_tup_ins,'FM999G999G999G999'), 16) AS "INSERTSs"
FROM pg_stat_all_tables
ORDER BY n_tup_ins DESC
LIMIT 10;

