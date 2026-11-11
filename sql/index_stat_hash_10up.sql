SELECT 
    --t.spcname AS "Tbs",
    n.nspname AS "Schema",
    c.relname AS "Name",
    CASE c.relkind 
        WHEN 'i' THEN 'index' 
        WHEN 'I' THEN 'partitioned index' 
        END AS "Type",
    pg_get_userbyid(c.relowner) AS "Owner",
    --pg_size_pretty(pg_table_size(c.oid)) AS "Table Size",
    lpad(pg_size_pretty(pg_relation_size(c.oid)),11) AS "Index Size",
    lpad(to_char(c.reltuples,'FM999G999G999G999G999'),20) AS "Rows",
    version,
    bucket_pages,
    overflow_pages,
    bitmap_pages,
    unused_pages,
    live_items,
    dead_items,
    free_percent
FROM 
         pg_class c
    JOIN pg_index i ON c.oid = i.indexrelid
    JOIN pg_opclass op ON i.indclass[0] = op.oid
    JOIN pg_am am ON op.opcmethod = am.oid
     LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace,
     LATERAL (SELECT * FROM pgstathashindex(c.oid)) l
WHERE 
        c.relkind = 'i'  -- not 'I': a partitioned index has no storage to inspect
    AND am.amname = 'hash'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND NOT pg_is_other_temp_schema(c.relnamespace)
ORDER BY pg_relation_size(c.oid) DESC
LIMIT 20;
