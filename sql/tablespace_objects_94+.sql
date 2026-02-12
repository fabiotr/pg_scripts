SELECT
    t.spcname AS "Name",
    pg_get_userbyid(t.spcowner) AS "Owner",
	count(*) FILTER (WHERE c.relkind = 'r') AS "Tables",
	count(*) FILTER (WHERE c.relkind = 'i') AS "Indexes",
	count(*) FILTER (WHERE c.relkind = 'm') AS "M Views",
	count(*) FILTER (WHERE c.relkind = 'p') AS "P Tables", 
	count(*) FILTER (WHERE c.relkind = 'I') AS "P Indexes"
	--count(*) FILTER (WHERE c.relkind = 't') AS "Toast", 
    --count(*) FILTER (WHERE c.relkind = 's') AS "Sequences", 
	--count(*) FILTER (WHERE c.relkind = 'v') AS "View",
	--count(*) FILTER (WHERE c.relkind = 'c') AS "Composite type", 
	--count(*) FILTER (WHERE c.relkind = 'f') AS "Foreign Table",
FROM 
	pg_tablespace t
	LEFT JOIN pg_class c ON c.reltablespace = t.oid
	LEFT JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE 
	t.spcname != 'pg_default' AND
	n.nspname NOT IN ('pg_catalog', 'pg_toast')
GROUP BY t.spcname, t.spcowner, t.spcacl, t.spcoptions, t.oid
UNION
SELECT
    t.spcname AS "Name",
    pg_get_userbyid(t.spcowner) AS "Owner",
	count(*) FILTER (WHERE c.relkind = 'r') AS "Tables",
	count(*) FILTER (WHERE c.relkind = 'i') AS "Indexes",
	count(*) FILTER (WHERE c.relkind = 'm') AS "M Views",
	count(*) FILTER (WHERE c.relkind = 'p') AS "Partitioned Table", 
	count(*) FILTER (WHERE c.relkind = 'I') AS "Partitioned Index"
	--count(*) FILTER (WHERE c.relkind = 't') AS "Toast", 
    --count(*) FILTER (WHERE c.relkind = 's') AS "Sequences", 
	--count(*) FILTER (WHERE c.relkind = 'v') AS "View",
	--count(*) FILTER (WHERE c.relkind = 'c') AS "Composite type", 
	--count(*) FILTER (WHERE c.relkind = 'f') AS "Foreign Table",
FROM 
	pg_tablespace t,
	pg_class c,
	pg_namespace n
WHERE 
	c.relnamespace = n.oid AND
	c.reltablespace = 0 AND
	t.spcname =  'pg_default' AND
	n.nspname NOT IN ('pg_catalog', 'pg_toast')
GROUP BY t.spcname, t.spcowner, t.spcacl, t.spcoptions, t.oid
ORDER BY "Name";
