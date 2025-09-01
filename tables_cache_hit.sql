SELECT schemaname, relname, 
    pg_size_pretty(pg_total_relation_size(relid)) AS "Size", 
    pg_size_pretty(pg_relation_size(relid,'main')) AS "Heap size",
    pg_size_pretty(pg_table_size(relid) - pg_relation_size(relid,'main')) AS "Toast size",
    to_char((coalesce(heap_blks_hit,0) + coalesce(heap_blks_read,0) + coalesce(idx_blks_hit,0) + idx_blks_read + coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) + tidx_blks_hit + tidx_blks_read) /
        SUM(heap_blks_hit + heap_blks_read + coalesce(idx_blks_hit,0) + coalesce(idx_blks_read,0) + coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) + tidx_blks_hit + tidx_blks_read) OVER(),'990D99') || ' %' AS "Avg weight",
    to_char(CASE heap_blks_hit  WHEN 0 THEN 0 ELSE 100 * (heap_blks_hit  + heap_blks_read)  / (SUM (heap_blks_hit  + heap_blks_read)  OVER ()) END,'990D99') || ' %' AS "Heap  weight",
    to_char(CASE toast_blks_hit WHEN 0 THEN 0 ELSE 100 * (toast_blks_hit + toast_blks_read) / (SUM (toast_blks_hit + toast_blks_read) OVER ()) END,'990D99') || ' %' AS "Toast weight",
    to_char(CASE tidx_blks_hit  WHEN 0 THEN 0 ELSE 100 * (tidx_blks_hit  + tidx_blks_read)  / (SUM (tidx_blks_hit  + tidx_blks_read)  OVER ()) END,'990D99') || ' %' AS "Tidx  weight",
    to_char(CASE heap_blks_hit  WHEN 0 THEN 0 ELSE 100 * heap_blks_hit::NUMERIC  / (heap_blks_hit  + heap_blks_read)  END,'990D99') || ' %' AS "Heap  hit",
    to_char(CASE toast_blks_hit WHEN 0 THEN 0 ELSE 100 * toast_blks_hit::NUMERIC / (toast_blks_hit + toast_blks_read) END,'990D99') || ' %' AS "Toast hit",
    to_char(CASE tidx_blks_hit  WHEN 0 THEN 0 ELSE 100 * tidx_blks_hit::NUMERIC  / (tidx_blks_hit  + tidx_blks_read)  END,'990D99') || ' %' AS "Tidx  hit"
FROM pg_statio_all_tables 
ORDER BY coalesce(heap_blks_hit,0) + coalesce(heap_blks_read,0) + coalesce(idx_blks_hit,0) + idx_blks_read + coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) + tidx_blks_hit + tidx_blks_read DESC NULLS LAST
--ORDER BY  heap_blks_hit  + heap_blks_read DESC NULLS LAST
--ORDER BY  toast_blks_hit  + toast_blks_read DESC NULLS LAST
--ORDER BY  tidx_blks_hit  + tidx_blks_read DESC NULLS LAST
LIMIT 40;
