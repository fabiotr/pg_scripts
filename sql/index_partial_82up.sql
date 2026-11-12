SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    i.relname AS indexname,
    --t.spcname AS tablespace,
    pg_get_indexdef(i.oid) AS indexdef
FROM pg_index x
     JOIN pg_class c ON c.oid = x.indrelid
     JOIN pg_class i ON i.oid = x.indexrelid
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     LEFT JOIN pg_tablespace t ON t.oid = i.reltablespace
WHERE
    x.indpred IS NOT NULL AND
    c.relkind IN ('r', 'm', 'p') AND
    i.relkind IN('i', 'I')
ORDER BY 1,2,3,4;
