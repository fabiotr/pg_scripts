SELECT 
	n.nspname AS "Schema",
	c.relname AS "Name",
	pg_get_userbyid(c.relowner) AS "Owner",
	pg_size_pretty(pg_table_size(c.oid)) AS "Size"
FROM pg_class c
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE 
	c.relkind = 'm'  AND 
	n.nspname !~ '^pg_toast' AND 
	pg_table_is_visible(c.oid)
ORDER BY n.nspname, c.relname;
