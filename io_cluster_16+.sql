SELECT
	backend_type, 
	object, 
	context,
	pg_size_pretty(reads      * op_bytes / (EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24))) AS "Reads / Day",
	pg_size_pretty(writes     * op_bytes / (EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24))) AS "Writes / Day",
	pg_size_pretty(writebacks * op_bytes / (EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24))) AS "Writebacks / Day",
	pg_size_pretty(extends    * op_bytes / (EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24))) AS "Extends / Day",
	trunc(evictions  / (EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24)),1) AS "Evictions / Day",
	trunc(reuses     / (EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24)),1) AS "Reuses / Day",
	trunc(fsyncs     / (EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24)),1) AS "fsyncs / Day",
	trunc(hits       / (EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24)),1) AS "Hits / Day",
	date_trunc('second', read_time      / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND') AS "Read Time / Day",
	date_trunc('second', write_time     / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND') AS "Write Time / Day",
	date_trunc('second', writeback_time / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND') AS "Writeback Time / Day",
	date_trunc('second', extend_time    / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND') AS "Extend Time / Day",
	date_trunc('second', fsync_time     / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND') AS "Fsync Time / Day"
FROM pg_stat_io
WHERE reads <> 0 OR writes <> 0 OR extends <> 0
ORDER BY COALESCE (writes,0) + COALESCE (reads,0) + COALESCE (extends,0) DESC;
