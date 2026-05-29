SELECT 
	schemaname   AS "Schema", 
	relname      AS "Table",
	indexrelname AS "Index",
	lpad(pg_size_pretty(pg_relation_size(relid)),7)       AS "Table Size",
	lpad(pg_size_pretty(pg_relation_size(indexrelid)),7) AS "Index Size",
	lpad(pg_size_pretty(round((current_setting('block_size')::bigint * idx_blks_hit)  / reset_days)::bigint),7) AS "Hit/Day",
	lpad(pg_size_pretty(round((current_setting('block_size')::bigint * idx_blks_read) / reset_days)::bigint),7) AS "Read/Day",
	CASE idx_blks_hit WHEN 0 THEN NULL ELSE round(idx_blks_hit::numeric*100 / (idx_blks_hit + idx_blks_read),1) END AS "Hit %" ,
	round(100 * idx_blks_hit  / sum(idx_blks_hit)  OVER(),1) AS "Hit/Tot %", 
	round(100 * idx_blks_read / sum(idx_blks_read) OVER(),1) AS "Read/Tot %"
FROM 
	pg_statio_all_indexes 
	JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
WHERE schemaname != 'pg_toast'
ORDER BY idx_blks_read DESC 
LIMIT 10;
