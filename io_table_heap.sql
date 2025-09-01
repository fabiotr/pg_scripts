SELECT 
	schemaname   AS "Schema", 
	relname      AS "Table",
	pg_size_pretty(pg_table_size(relid))          AS "Table Size",
	pg_size_pretty(pg_relation_size(relid))       AS "Heap  Size",
	pg_size_pretty(trunc((current_setting('block_size')::bigint * heap_blks_hit)  / reset_days)) AS "Hit/Day",
	pg_size_pretty(trunc((current_setting('block_size')::bigint * heap_blks_read) / reset_days)) AS "Read/Day",
	CASE heap_blks_hit WHEN 0 THEN NULL ELSE trunc(heap_blks_hit::numeric*100 / (heap_blks_hit + heap_blks_read),1) END AS "Hit %" ,
	trunc(100 * heap_blks_hit  / sum(heap_blks_hit)  OVER(),1) AS "Hit/Tot %", 
	trunc(100 * heap_blks_read / sum(heap_blks_read) OVER(),1) AS "Read/Tot %"
FROM 
	pg_statio_all_tables
	JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
WHERE schemaname != 'pg_toast'
ORDER BY coalesce(heap_blks_hit,0) + coalesce(heap_blks_read,0) DESC 
LIMIT 10;
