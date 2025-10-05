SELECT 
	schemaname AS "Schema", 
	relname    AS "Sequence",
	pg_size_pretty(trunc(current_setting('block_size')::bigint * blks_hit)::bigint)  AS "Hit",
	pg_size_pretty(trunc(current_setting('block_size')::bigint * blks_read)::bigint) AS "Read",
	CASE blks_hit WHEN 0 THEN NULL ELSE trunc(blks_hit::numeric*100 / (blks_hit + blks_read),1) END AS "Hit %" ,
	trunc(100 * blks_hit / sum(blks_hit) OVER(),1) AS "Hit/Tot", 
	CASE blks_read WHEN 0 THEN NULL ELSE trunc(100 * blks_read / sum(blks_read) OVER(),1) END AS "Read/Tot"
FROM pg_statio_all_sequences 
ORDER BY blks_hit + blks_read DESC 
LIMIT 10;
