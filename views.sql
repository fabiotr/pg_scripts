\set QUIET on
\timing off

SELECT schemaname, viewname, viewowner 
FROM pg_views 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1,2;
\set QUIET off
