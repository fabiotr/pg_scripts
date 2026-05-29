SELECT 
	schemaname   AS "Schema", 
	relname      AS "Table",
	lpad(pg_size_pretty(pg_table_size(relid)),7)          AS "Table Size",
	lpad(pg_size_pretty(pg_relation_size(relid)),7)       AS "Heap  Size",
	lpad(pg_size_pretty(round((current_setting('block_size')::bigint * heap_blks_hit)  / reset_days)::bigint),7) AS "Hit/Day",
	lpad(pg_size_pretty(round((current_setting('block_size')::bigint * heap_blks_read) / reset_days)::bigint),7) AS "Read/Day",
	CASE heap_blks_hit WHEN 0 THEN NULL ELSE trunc(heap_blks_hit::numeric*100 / (heap_blks_hit + heap_blks_read),1) END AS "Hit %" ,
	round(100 * heap_blks_hit  / sum(heap_blks_hit)  OVER(),1) AS "Hit/Tot %", 
	round(100 * heap_blks_read / sum(heap_blks_read) OVER(),1) AS "Read/Tot %"
FROM 
	pg_statio_all_tables
	JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
WHERE schemaname != 'pg_toast'
ORDER BY heap_blks_read DESC 
LIMIT 10;
