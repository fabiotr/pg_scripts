SELECT 
	schemaname AS "Schema",
	relname AS "Table",  
	lpad(to_char(n_tup_upd,'FM999G999G999G999'), 16) AS "UPDATEs"
FROM pg_stat_all_tables
ORDER BY n_tup_upd DESC
LIMIT 10;
