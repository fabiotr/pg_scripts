SELECT
    --t.spcname AS "Tbs",
    n.nspname AS "Schema",
    c.relname AS "Name",
    CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'm' THEN 'materialized view'
        WHEN 'p' THEN 'partition table'
        END AS "Type",
    CASE c.relpersistence
        WHEN 'p' THEN 'permanent'
        WHEN 'u' THEN 'unlogged'
    END AS persistence,
    pg_get_userbyid(c.relowner) AS "Owner",
  pg_size_pretty(pg_total_relation_size(c.oid)) AS "Total Size",
  pg_size_pretty(pg_table_size(c.oid)) AS "Table Size",
  pg_size_pretty(pg_table_size(t.oid)) AS "Toast Size",
  trunc( 100 * pg_table_size(t.oid) / pg_table_size(c.oid)) AS "Toast %"
FROM pg_class c
    JOIN pg_class t ON t.oid = c.reltoastrelid
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
ORDER BY pg_table_size(t.oid) DESC
LIMIT 20;
