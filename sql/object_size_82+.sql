SELECT 
    coalesce(t.spcname, nullif(current_setting('default_tablespace'),''), 'pg_default') AS "Tablespace",
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
    lpad(pg_size_pretty(pg_relation_size(c.oid)),7)       AS "Size",
    lpad(to_char(c.reltuples,'FM999G999G999G999G999'),15) AS "Rows"
FROM pg_class c
     LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     
WHERE c.relkind IN ('r','p', 'i', 'I', 'v','m','S','f','')
    AND n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_toast'
ORDER BY pg_relation_size(c.oid) DESC
LIMIT 20;
