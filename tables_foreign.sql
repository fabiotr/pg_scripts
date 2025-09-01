SELECT 
	s.srvname AS "Server",
	n.nspname AS "Schema",
	c.relname AS "Table",
	pg_get_userbyid(c.relowner) as "Owner",
	CASE WHEN ftoptions 
		IS NULL THEN '' 
		ELSE   '(' || array_to_string(ARRAY(
			SELECT quote_ident(option_name) ||  ' ' ||   quote_literal(option_value)  
			FROM   pg_options_to_table(ftoptions)),  ', ') || ')'   
		END AS "FDW options"
FROM 
	pg_foreign_table ft
	JOIN pg_class c ON c.oid = ft.ftrelid
	JOIN pg_namespace n ON n.oid = c.relnamespace
	JOIN pg_foreign_server s ON s.oid = ft.ftserver
WHERE pg_table_is_visible(c.oid)
ORDER BY s.srvname, n.nspname, c.relname;
