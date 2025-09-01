SELECT 
	n.nspname                   AS "Schema",
	c.relname                   AS "Table",
	pg_get_userbyid(c.relowner) AS "Owner",
	--t.spcname                   AS "Tablespace",
	to_char(c.reltuples,'999G999G999G990')  AS "Rows",
	pg_size_pretty(pg_relation_size(c.oid)) AS "Size"
FROM 
	pg_class c
	LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
	LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
WHERE 
	c.relkind    IN ('r', 'p') AND
	c.relhasindex = FALSE AND
	c.relpersistence = 'p' AND
	n.nspname    NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname;
