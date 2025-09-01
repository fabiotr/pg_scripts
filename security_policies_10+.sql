SELECT 
	schemaname                   AS "Schema",
	tablename                    AS "Table", 
	policyname                   AS "Policy",
	permissive,
	array_to_string(roles, ', ') AS "Roles",
	cmd                          AS "Cmd Type",
	qual                         AS "Qualification",
	with_check                   AS "WITH CHECK"
FROM pg_policies 
ORDER BY 1,2,3;
