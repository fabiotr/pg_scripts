SELECT 
	schemaname   AS "Schema", 
	relname      AS "Table",
	pg_size_pretty(pg_relation_size(relid))       AS "Heap  Size",
	pg_size_pretty(trunc(current_setting('block_size')::bigint * heap_blks_hit)::bigint)  AS "Hit",
	pg_size_pretty(trunc(current_setting('block_size')::bigint * heap_blks_read)::bigint) AS "Read",
	CASE heap_blks_hit WHEN 0 THEN NULL ELSE trunc(heap_blks_hit::numeric*100 / (heap_blks_hit + heap_blks_read),1) END AS "Hit %" ,
	trunc(100 * heap_blks_hit  / sum(heap_blks_hit)  OVER(),1) AS "Hit/Tot %", 
	trunc(100 * heap_blks_read / sum(heap_blks_read) OVER(),1) AS "Read/Tot %"
FROM pg_statio_all_tables
WHERE schemaname != 'pg_toast'
ORDER BY coalesce(heap_blks_hit,0) + coalesce(heap_blks_read,0) DESC 
LIMIT 10;
