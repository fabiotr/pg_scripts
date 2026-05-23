SELECT c.conrelid::regclass AS "table",
       string_agg(a.attname, ',' ORDER BY x.n) AS columns,
       pg_size_pretty(pg_relation_size(c.conrelid)) AS size,
       --c.conname AS constraint,
       c.confrelid::regclass AS referenced_table
FROM 
    pg_constraint c
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
GROUP BY c.conrelid, c.conname, c.confrelid
ORDER BY pg_relation_size(c.conrelid) DESC;
