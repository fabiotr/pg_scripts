\set QUIET on
\timing off

SELECT 
  schemaname AS "Schema", 
  viewname   AS "View", 
  viewowner  AS "Owner"
FROM pg_views 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1,2;
\timing on
\set QUIET off
