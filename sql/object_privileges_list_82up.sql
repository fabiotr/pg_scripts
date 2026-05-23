SELECT 
	nspname,
	relname,
	CASE relkind
	WHEN 'r' THEN 'TABLE'
	WHEN 'v' THEN 'VIEW'
	WHEN 'm' THEN 'MATERIALIZED VIEW'
	WHEN 'i' THEN 'INDEX'
	WHEN 'S' THEN 'SEQUENCE'
	WHEN 's' THEN 'special'
	WHEN 'f' THEN 'FOREIGN TABLE'
	WHEN 'p' THEN 'PARTITION TABLE'
	END AS "Type",
	relacl
FROM
	pg_class c
	JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE relacl IS NOT NULL
ORDER BY nspname, relname, relkind;
