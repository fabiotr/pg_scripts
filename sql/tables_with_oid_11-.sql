--tables with OID (until PG 11) - pg_class version
--pg_namespace instead of regnamespace, which only exists from 9.5
SELECT n.nspname AS "Schema", c.relname AS "Name", c.relhasoids,
CASE c.relkind
	WHEN 'r' THEN 'table'
	WHEN 'v' THEN 'view'
	WHEN 'i' THEN 'index'
	WHEN 'S' THEN 'sequence'
	WHEN 's' THEN 'special'
	WHEN 'f' THEN 'foreign table'
	WHEN 't' THEN 'TOAST table'
	WHEN 'c' THEN 'composite type'
	WHEN 'p' THEN 'partitioned table'
	WHEN 'I' THEN 'partitioned index'
END AS "Type"
, lpad(pg_size_pretty(pg_relation_size(c.oid)), 11) AS "Size"
FROM pg_class c
	JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
AND c.relhasoids = TRUE
AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;
