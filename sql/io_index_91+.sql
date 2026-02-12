SELECT 
	schemaname   AS "Schema", 
	relname      AS "Table",
	indexrelname AS "Index",
	pg_size_pretty(pg_relation_size(relid))       AS "Table Size",
	pg_size_pretty(pg_relation_size(indexrelid)) AS "Index Size",
	pg_size_pretty(trunc((current_setting('block_size')::bigint * idx_blks_hit)  / reset_days)::bigint) AS "Hit/Day",
	pg_size_pretty(trunc((current_setting('block_size')::bigint * idx_blks_read) / reset_days)::bigint) AS "Read/Day",
	CASE idx_blks_hit WHEN 0 THEN NULL ELSE trunc(idx_blks_hit::numeric*100 / (idx_blks_hit + idx_blks_read),1) END AS "Hit %" ,
	trunc(100 * idx_blks_hit  / sum(idx_blks_hit)  OVER(),1) AS "Hit/Tot %", 
	trunc(100 * idx_blks_read / sum(idx_blks_read) OVER(),1) AS "Read/Tot %"
FROM 
	pg_statio_all_indexes 
	JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
WHERE schemaname != 'pg_toast'
ORDER BY coalesce(idx_blks_hit,0) + coalesce(idx_blks_read,0) DESC 
LIMIT 10;
