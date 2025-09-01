SELECT n.nspname AS schemaname,
    c.relname AS tablename,
    i.relname AS indexname,
    t.spcname AS tablespace,
    x.indisvalid AS "Is invalid?",
    x.indisready AS "Is ready?",
    x.indislive  AS "Is live?",
    x.indcheckxmin AS "Is wraparound?",
    pg_get_indexdef(i.oid) AS indexdef
FROM pg_index x
     JOIN pg_class c ON c.oid = x.indrelid
     JOIN pg_class i ON i.oid = x.indexrelid
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     LEFT JOIN pg_tablespace t ON t.oid = i.reltablespace
WHERE 
    (NOT x.indisvalid OR
     NOT x.indisready OR
     NOT x.indislive  OR 
         x.indcheckxmin) AND
    c.relkind IN ('r', 'm', 'p') AND 
    i.relkind IN('i', 'I') AND
    NOT EXISTS (SELECT 1 FROM pg_stat_progress_create_index pi WHERE pi.relid = x.indrelid)
ORDER BY 1,2,3,4;
