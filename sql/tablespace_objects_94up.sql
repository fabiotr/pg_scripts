SELECT
		t.spcname AS "Name",
		count(*) FILTER (WHERE c.relkind = 'r') AS "Tables",
		count(*) FILTER (WHERE c.relkind = 'i') AS "Indexes",
		count(*) FILTER (WHERE c.relkind = 'm') AS "M Views",
		count(*) FILTER (WHERE c.relkind = 'p') AS "P Tables", 
		count(*) FILTER (WHERE c.relkind = 'I') AS "P Indexes",
		count(*) FILTER (WHERE c.relkind = 't') AS "Toast", 
		count(*) FILTER (WHERE c.relkind = 's') AS "Sequences", 
		count(*) FILTER (WHERE c.relkind = 'v') AS "View",
		count(*) FILTER (WHERE c.relkind = 'c') AS "Composite type", 
		count(*) FILTER (WHERE c.relkind = 'f') AS "Foreign Table"
	FROM 
		pg_tablespace t
		JOIN pg_class c ON c.reltablespace = t.oid
	WHERE 
		c.reltablespace != 0 AND
		t.spcname != 'pg_global' AND
		c.relnamespace NOT IN (SELECT oid FROM pg_namespace WHERE nspname = 'pg_catalog')
	GROUP BY t.spcname, t.spcacl, t.spcoptions, t.oid
UNION
SELECT
        t.spcname AS "Name",
	count(*) FILTER (WHERE c.relkind = 'r') AS "Tables",
	count(*) FILTER (WHERE c.relkind = 'i') AS "Indexes",
	count(*) FILTER (WHERE c.relkind = 'm') AS "M Views",
	count(*) FILTER (WHERE c.relkind = 'p') AS "Partitioned Table", 
	count(*) FILTER (WHERE c.relkind = 'I') AS "Partitioned Index",
	count(*) FILTER (WHERE c.relkind = 't') AS "Toast", 
    count(*) FILTER (WHERE c.relkind = 's') AS "Sequences", 
	count(*) FILTER (WHERE c.relkind = 'v') AS "View",
	count(*) FILTER (WHERE c.relkind = 'c') AS "Composite type", 
	count(*) FILTER (WHERE c.relkind = 'f') AS "Foreign Table"
FROM 
	pg_class c,
	pg_database d 
	JOIN pg_tablespace t ON d.dattablespace = t.oid 
WHERE 
	c.reltablespace = 0 AND
	c.relnamespace NOT IN (SELECT oid FROM pg_namespace WHERE nspname = 'pg_catalog') AND
	datname = current_database()
GROUP BY t.spcname
ORDER BY "Name";
