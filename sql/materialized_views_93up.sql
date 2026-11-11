SELECT 
	n.nspname AS "Schema",
	c.relname AS "Name",
	pg_get_userbyid(c.relowner) AS "Owner",
	lpad(pg_size_pretty(pg_table_size(c.oid)), 11) AS "Size"
FROM pg_class c
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE 
	c.relkind = 'm'  AND 
	n.nspname !~ '^pg_toast'
ORDER BY n.nspname, c.relname;
