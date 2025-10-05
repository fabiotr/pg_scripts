SELECT
    rr.rolname  AS "Grantor",
	re.rolname	AS "Grantee",
	g.nspname	AS "Schema",
	g.relname	AS "Table",
	CASE g.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        WHEN 'i' THEN 'INDEX'
        WHEN 'S' THEN 'SEQUENCE'
        WHEN 's' THEN 'special'
        WHEN 'f' THEN 'FOREIGN TABLE'
        WHEN 'p' THEN 'PARTITION TABLE'
        END AS "Type",
	 array_to_string(array_agg(g.privilege_type),', ') priv,
	g.is_grantable
FROM
	(SELECT 
		nspname,
		relname,
		relkind,
		(aclexplode(relacl)).*
	FROM
		pg_class c
		JOIN pg_namespace n ON c.relnamespace = n.oid
	WHERE relacl IS NOT NULL) g
    JOIN pg_roles rr ON rr.oid = g.grantee
	JOIN pg_roles re ON re.oid = g.grantor    
GROUP BY rr.rolname, re.rolname, g.nspname, g.relname, g.relkind, g.is_grantable
ORDER BY rr.rolname, re.rolname, g.nspname, g.relname;
