SELECT 
	schemaname AS "Schema", 
	relname    AS "Sequence",
	lpad(pg_size_pretty(round((current_setting('block_size')::bigint * blks_hit)  / reset_days)::bigint),11) AS "Hit/Day",
	lpad(pg_size_pretty(round((current_setting('block_size')::bigint * blks_read) / reset_days)::bigint),11) AS "Read/Day",
	CASE blks_hit WHEN 0 THEN NULL ELSE round(blks_hit::numeric*100 / (blks_hit + blks_read),1) END AS "Hit %" ,
	round(100 * blks_hit / nullif(sum(blks_hit) OVER(), 0),1) AS "Hit/Tot", 
	CASE blks_read WHEN 0 THEN NULL ELSE round(100 * blks_read / nullif(sum(blks_read) OVER(), 0),1) END AS "Read/Tot"
FROM 
	pg_statio_all_sequences 
	JOIN (SELECT datname, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
ORDER BY blks_read DESC 
LIMIT 10;
