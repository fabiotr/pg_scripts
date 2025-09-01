SELECT 
	name,  
	trunc(100 * blks_hit::numeric / nullif(blks_hit + blks_read,0),1) AS "% Hit",
	trim(pg_size_pretty((blks_hit     * current_setting('block_size')::bigint) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))::numeric)) AS "Hit / Day",
	trim(pg_size_pretty((blks_read    * current_setting('block_size')::bigint) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))::numeric)) AS "Read / Day",
	trim(pg_size_pretty((blks_written * current_setting('block_size')::bigint) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))::numeric)) AS "Write / Day",
	trim(pg_size_pretty((blks_zeroed  * current_setting('block_size')::bigint) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))::numeric)) AS "Zeroed / Day",
	trim(pg_size_pretty((blks_exists  * current_setting('block_size')::bigint) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))::numeric)) AS "Exists / Day",
	trunc(flushes   / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))::numeric,1) AS "Flushes / Day",
	trunc(truncates / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))::numeric,1) AS "Truncates / Day",
	date_trunc('second', stats_reset) AS stats_reset
FROM pg_stat_slru
WHERE blks_read + blks_hit > 0
ORDER BY blks_hit DESC, name;

