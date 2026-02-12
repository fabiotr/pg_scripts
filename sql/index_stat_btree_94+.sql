SELECT 
    n.nspname as "Schema",
    c.relname as "Name",
--    pg_get_userbyid(c.relowner) AS "Owner",
    --pg_size_pretty(pg_table_size(c.oid)) AS "Table Size",
    pg_size_pretty(index_size) AS "Index Size",
    ltrim(to_char(c.reltuples,'999G999G999G999G999')) AS "Rows",
    trunc(avg_leaf_density::numeric,1)   AS "Avg Leaf Density",
    trunc(leaf_fragmentation::numeric,1) AS "Leaf Fragmentation",
    tree_level AS "Tree Level",
    internal_pages AS "Internal P", 
    leaf_pages AS "Leaf P.",
    empty_pages AS "Empty P.", 
    deleted_pages AS "Deleted P."
FROM 
         pg_index i
    JOIN pg_class c ON c.oid = i.indexrelid
    JOIN pg_class ct ON ct.oid = i.indrelid
    JOIN pg_am am ON c.relam = am.oid
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace,
    LATERAL (SELECT * FROM pgstatindex(i.indexrelid)) l
WHERE 
        c.relkind IN ('i','I')
    AND am.amname = 'btree'
    AND n.nspname != 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND pg_catalog.pg_table_is_visible(c.oid)
    AND (avg_leaf_density <= 70 OR leaf_fragmentation >= 20)
ORDER BY index_size DESC
LIMIT 20;
