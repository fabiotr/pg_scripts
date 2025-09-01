SELECT 'CREATE INDEX CONCURRENTLY ON ' || 
       n.nspname || '.' || c.conrelid::regclass || 
       ' (' || string_agg(a.attname, ',' ORDER BY x.n) || ');' AS command
FROM
    pg_constraint c
    JOIN pg_namespace n ON n.oid = c.connamespace 
   CROSS JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS x(attnum, n)
   JOIN pg_attribute a ON a.attnum = x.attnum AND a.attrelid = c.conrelid
WHERE
    pg_relation_size(c.conrelid) > 10*1024*1024 AND
    NOT EXISTS (
        SELECT 1
        FROM pg_index i
        WHERE
            i.indrelid = c.conrelid AND
            (i.indkey::smallint[])[0:cardinality(c.conkey)-1] @> c.conkey)
        AND c.contype = 'f'
GROUP BY n.nspname, c.conrelid, c.conname, c.confrelid
ORDER BY pg_relation_size(c.conrelid) DESC;
