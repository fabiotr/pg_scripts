SELECT 
	schemaname AS "Schema", 
	relname    AS "Sequence",
	pg_size_pretty(trunc((current_setting('block_size')::bigint * blks_hit)  / reset_days)::bigint) AS "Hit/Day",
	pg_size_pretty(trunc((current_setting('block_size')::bigint * blks_read) / reset_days)::bigint) AS "Read/Day",
	CASE blks_hit WHEN 0 THEN NULL ELSE trunc(blks_hit::numeric*100 / (blks_hit + blks_read),1) END AS "Hit %" ,
	trunc(100 * blks_hit / sum(blks_hit) OVER(),1) AS "Hit/Tot", 
	CASE blks_read WHEN 0 THEN NULL ELSE trunc(100 * blks_read / sum(blks_read) OVER(),1) END AS "Read/Tot"
FROM 
	pg_statio_all_sequences 
	JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
ORDER BY blks_hit + blks_read DESC 
LIMIT 10;
