SELECT 
    --t.spcname AS "Tablespace",
    n.nspname as "Schema",
    c.relname as "Name",
    CASE c.relkind 
        WHEN 'r' THEN 'table' 
        WHEN 'v' THEN 'view' 
        WHEN 'm' THEN 'materialized view' 
        WHEN 'i' THEN 'index' 
        WHEN 'S' THEN 'sequence' 
        WHEN 's' THEN 'special' 
        WHEN 'f' THEN 'foreign table' 
        WHEN 'p' THEN 'partition table' 
        END AS "Type",
    pg_get_userbyid(c.relowner) AS "Owner",
    pg_size_pretty(pg_table_size(c.oid)) AS "Size",
    ltrim(to_char(c.reltuples,'999G999G999G999G999')) AS "Rows"--,
    --pg_size_pretty(trunc(pg_table_size(c.oid) / c.reltuples)::numeric) AS "Row size"
FROM pg_class c
     LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     
WHERE c.relkind IN ('r','p', 'i', 'I', 'v','m','S','f','')
    AND c.relpersistence != 't'  
    AND n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_toast'
    --AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY pg_table_size(c.oid) DESC
LIMIT 20;
