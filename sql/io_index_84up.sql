SELECT 
	schemaname   AS "Schema", 
	relname      AS "Table",
	indexrelname AS "Index",
	lpad(pg_size_pretty(pg_relation_size(relid)), 11)      AS "Table Size",
	lpad(pg_size_pretty(pg_relation_size(indexrelid)), 11) AS "Index Size",
	lpad(pg_size_pretty(trunc(current_setting('block_size')::bigint * idx_blks_hit)::bigint), 11)  AS "Hit",
	lpad(pg_size_pretty(trunc(current_setting('block_size')::bigint * idx_blks_read)::bigint), 11) AS "Read",
	CASE idx_blks_hit WHEN 0 THEN NULL ELSE trunc(idx_blks_hit::numeric*100 / (idx_blks_hit + idx_blks_read),1) END AS "Hit %" ,
	trunc(100 * idx_blks_hit  / sum(idx_blks_hit)  OVER(),1) AS "Hit/Tot %", 
	trunc(100 * idx_blks_read / sum(idx_blks_read) OVER(),1) AS "Read/Tot %"
FROM 
	pg_statio_all_indexes 
WHERE schemaname != 'pg_toast'
ORDER BY idx_blks_read DESC 
LIMIT 10;
