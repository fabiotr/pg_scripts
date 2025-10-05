SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    i.relname AS indexname,
    pg_size_pretty(pg_table_size(x.indrelid)) AS table_size,
    pg_size_pretty(pg_relation_size(x.indexrelid)) AS index_size,
    --t.spcname AS tablespace,
    pg_get_indexdef(i.oid) AS indexdef
FROM pg_index x
     JOIN pg_class c ON c.oid = x.indrelid
     JOIN pg_class i ON i.oid = x.indexrelid
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     LEFT JOIN pg_tablespace t ON t.oid = i.reltablespace
WHERE
    c.relpages > 100 AND
    pg_relation_size(x.indexrelid) > pg_table_size(x.indrelid) * 0.5 AND
    c.relkind IN ('r', 'm', 'p') AND
    i.relkind IN('i', 'I')
ORDER BY 1,2,3,4;
