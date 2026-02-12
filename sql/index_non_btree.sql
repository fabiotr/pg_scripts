SELECT 
    n.nspname AS schemaname,
    c.relname AS tablename,
    i.relname AS indexname,
    --t.spcname AS tablespace,
    pg_get_indexdef(i.oid) AS indexdef
FROM 
    pg_index x
    JOIN pg_class c ON c.oid = x.indrelid
    JOIN pg_class i ON i.oid = x.indexrelid
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_tablespace t ON t.oid = i.reltablespace
    JOIN pg_am am ON i.relam = am.oid
WHERE am.amname != 'btree'
GROUP BY n.nspname, c.relname, i.relname, t.spcname, i.oid
ORDER BY 1,2,3,4;
