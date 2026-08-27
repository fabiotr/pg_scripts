SELECT
	schemaname AS "Schema",
	tablename  AS "Table",
	rulename   AS "Rule",
	definition AS "Definition"
FROM pg_rules
WHERE schemaname != 'pg_catalog'
ORDER BY 1, 2, 3;
