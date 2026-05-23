SELECT 
	pubname AS "Publication", 
	schemaname || '.' || tablename AS "Table",
	rowfilter
FROM pg_publication_tables
ORDER BY 1,2;
