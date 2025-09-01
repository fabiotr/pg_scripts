--tabelas com OID (until PG 11) - pg_class version
SELECT relnamespace::regnamespace, relname, relhasoids,
CASE relkind 
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
END as "Type"
, pg_size_pretty(pg_relation_size( relnamespace::regnamespace || '.' || relname))
FROM pg_class 
WHERE relkind = 'r' 
AND relhasoids=true 
AND  relnamespace NOT IN ('pg_catalog'::regnamespace::oid,'information_schema'::regnamespace::oid);

