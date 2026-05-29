\set QUIET on
\timing off
SELECT 
	nspname AS "Schema",
	relname AS "Table",
      	CASE relkind 
	    WHEN 'r' THEN 'Table'
	    WHEN 'i' THEN 'Index'
	    WHEN 'S' THEN 'Sequence'
	    WHEN 't' THEN 'TOAST table'
	    WHEN 'v' THEN 'View'
	    WHEN 'm' THEN 'Materialized View'
	    WHEN 'c' THEN 'Composite type'
	    WHEN 'f' THEN 'Foreign Table'
	    WHEN 'p' THEN 'Partitioned Table'
	    WHEN 'I' THEN 'Ppartitioned index'
	    ELSE 'Unknow' END AS "Type", 
	reloptions AS "Options" 
FROM
    pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE 
	reloptions IS NOT NULL AND 
	nspname != 'pg_catalog'
ORDER BY 1,2;
\timing on
\set QUIET off
