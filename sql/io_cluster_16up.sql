SELECT
	backend_type,
	object,
	context,
	pg_size_pretty(trunc(reads      * op_bytes / reset_days))                    AS "Reads / Day",
	pg_size_pretty(trunc(writes     * op_bytes / reset_days))                    AS "Writes / Day",
	pg_size_pretty(trunc(writebacks * op_bytes / reset_days))                    AS "Writebacks / Day",
	pg_size_pretty(trunc(extends    * op_bytes / reset_days))                    AS "Extends / Day",
	trunc(evictions  / reset_days)                                             AS "Evictions / Day",
	trunc(reuses     / reset_days)                                             AS "Reuses / Day",
	trunc(fsyncs     / reset_days)                                             AS "fsyncs / Day",
	trunc(hits       / reset_days)                                             AS "Hits / Day",
	date_trunc('second', read_time      / reset_days * INTERVAL '1 MIlLISECOND') AS "Read Time / Day",
	date_trunc('second', write_time     / reset_days * INTERVAL '1 MIlLISECOND') AS "Write Time / Day",
	date_trunc('second', writeback_time / reset_days * INTERVAL '1 MIlLISECOND') AS "Writeback Time / Day",
	date_trunc('second', extend_time    / reset_days * INTERVAL '1 MIlLISECOND') AS "Extend Time / Day",
	date_trunc('second', fsync_time     / reset_days * INTERVAL '1 MIlLISECOND') AS "Fsync Time / Day"
FROM (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24) AS reset_days, * FROM pg_stat_io) AS i
WHERE reads <> 0 OR writes <> 0 OR extends <> 0
ORDER BY COALESCE (writes,0) + COALESCE (reads,0) + COALESCE (extends,0) DESC;
