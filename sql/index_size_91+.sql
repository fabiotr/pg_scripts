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
    ltrim(to_char(c.reltuples,'999G999G999G999G999')) AS "Rows",
    pg_size_pretty(pg_relation_size(i.indrelid)) AS "Table Size",
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS "Index Size",
    trunc(100 * pg_relation_size(i.indexrelid) / nullif(pg_relation_size(i.indrelid),0),1) AS "Ind/Table %"
FROM 
         pg_class c
    JOIN pg_index i ON c.oid = i.indexrelid
    JOIN pg_am am ON c.relam = am.oid
    LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE 
        c.relkind IN ('i','I')
    AND c.relpages > 0
    AND am.amname = 'btree'
    AND n.nspname != 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY c.relpages DESC
LIMIT 20;
