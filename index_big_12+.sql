SELECT 
    n.nspname AS "Schema",
    c.relname AS "Table",
    i.relname AS "Index",
    pg_size_pretty(pg_table_size(x.indrelid)) AS "Table Size",
    pg_size_pretty(pg_relation_size(x.indexrelid)) AS "Index Size",
    trunc(100 * pg_relation_size(x.indexrelid) / pg_table_size(x.indrelid),1) AS "Ind/Table %",
    --t.spcname AS tablespace,
    pg_get_indexdef(i.oid) AS indexdef
FROM pg_index x
     JOIN pg_class c ON c.oid = x.indrelid
     JOIN pg_class i ON i.oid = x.indexrelid
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     --LEFT JOIN pg_tablespace t ON t.oid = i.reltablespace
WHERE
    c.relpages > 100 AND
    pg_relation_size(x.indexrelid) > pg_table_size(x.indrelid) * 0.5 AND
    c.relkind IN ('r', 'm', 'p') AND
    i.relkind IN('i', 'I') AND
    NOT EXISTS (SELECT 1 FROM pg_stat_progress_create_index pi WHERE pi.relid = x.indrelid)
ORDER BY pg_relation_size(x.indexrelid) / pg_table_size(x.indrelid) DESC
