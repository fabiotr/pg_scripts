SELECT schemaname, relname, indexrelname,
    pg_size_pretty(pg_total_relation_size(relid)) AS "Size", 
    pg_size_pretty(pg_relation_size(relid,'main')) AS "Heap size",
    pg_size_pretty(pg_indexes_size(relid)) AS "Indexes size",
    pg_size_pretty(pg_relation_size(indexrelid)) AS "Index size",
    to_char(CASE idx_blks_hit   WHEN 0 THEN 0 ELSE 100 * (idx_blks_hit   + idx_blks_read)   / (SUM (idx_blks_hit   + idx_blks_read)   OVER ()) END,'990D99') || ' %' AS "Index weight",
    to_char(CASE idx_blks_hit   WHEN 0 THEN 0 ELSE 100 * idx_blks_hit::NUMERIC   / (idx_blks_hit   + idx_blks_read)   END,'990D99') || ' %' AS "Index hit"
FROM pg_statio_all_indexes
ORDER BY  idx_blks_hit  + idx_blks_read DESC NULLS LAST
LIMIT 10;

