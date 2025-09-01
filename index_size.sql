SELECT 
    t.spcname AS "Tbs",
    n.nspname as "Schema",
    c.relname as "Name",
    CASE c.relkind 
        WHEN 'i' THEN 'index' 
        WHEN 'I' THEN 'partitioned index' 
        END AS "Type",
    CASE c.relpersistence
        WHEN 'p' THEN 'permanent'
        WHEN 'u' THEN 'unlogged'
        WHEN 't' THEN 'temporary'
    END AS persistence,
    pg_get_userbyid(c.relowner) AS "Owner",
    --pg_size_pretty(pg_table_size(c.oid)) AS "Table Size",
    pg_size_pretty(index_size) AS "Index Size",
    ltrim(to_char(c.reltuples,'999G999G999G999G999')) AS "Rows",
    tree_level AS "Tree Level",
    internal_pages, 
    leaf_pages,
    empty_pages, 
    deleted_pages, 
    avg_leaf_density, 
    leaf_fragmentation
FROM pg_class c
     LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace,
     LATERAL (SELECT * FROM pgstatindex(c.oid)) l
WHERE c.relkind IN ('i','I')
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_toast'
      --AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY index_size DESC
LIMIT 20;
