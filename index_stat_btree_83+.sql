SELECT 
    nspname AS "Schema",
    "Table name",
    "Index name",
    "Owner",
    rows AS "Rows",
    pg_size_pretty(index_size) AS "Index size",
    avg_leaf_density AS "Avg leaf density",
    leaf_fragmentation AS "Leaf fragmentation",
    version AS "Version",
    tree_level AS "Tree level",
    root_block_no AS "N root block",
    internal_pages AS "Internal pages",
    leaf_pages AS "Leaf pages",
    empty_pages AS "Empty pages",
    deleted_pages AS "Deleted pages"
FROM 
    (SELECT 
        --t.spcname AS "Tbs",
        n.nspname,
        ct.relname AS "Table name",
	c.relname AS "Index name",
        pg_get_userbyid(c.relowner) AS "Owner",
        ltrim(to_char(c.reltuples,'999G999G999G999G999')) AS "rows",
        (pgstatindex(c.relname)).*
    FROM 
             pg_index i
        JOIN pg_class c ON c.oid = i.indexrelid
	JOIN pg_class ct ON ct.oid = i.indrelid
        JOIN pg_am am ON c.relam = am.oid
        --LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE 
            c.relkind IN ('i','I')
        AND am.amname = 'btree'
        AND n.nspname <> 'information_schema'
        AND n.nspname !~ '^pg_toast'
        AND pg_catalog.pg_table_is_visible(c.oid)
    ORDER BY c.relpages DESC
    LIMIT 20) ind
WHERE 
  avg_leaf_density <= 70 OR leaf_fragmentation >= 20;
