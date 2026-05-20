SELECT 
    backend_type,
    lpad(round(sum(writes) * 100 / t_writes,1) || ' %',6)                               AS "Write",
    lpad(pg_size_pretty(round(coalesce(sum(write_bytes)/reset_days, 0))),7)             AS "Write/Day",
    lpad(pg_size_pretty(round(coalesce(sum(extend_bytes)/reset_days, 0))),7)            AS "Extend/Day",
    to_char(coalesce(sum(write_time),      0) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Write T/Day",
    to_char(coalesce(sum(extend_time),     0) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Extend T/Day",
    to_char(coalesce(sum(writeback_time ), 0) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Writeback T/Day",
    to_char(coalesce(sum(fsync_time ),     0) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Fsync T/Day",
    lpad(round(100.0 * sum(coalesce(writeback_time,0) + coalesce(fsync_time,0))::numeric / 
        nullif(sum(coalesce(write_time,0) + coalesce(extend_time,0) + coalesce(writeback_time,0) + coalesce(fsync_time,0)),0)::numeric,1) 
        || ' %',6) AS "Physical Write T"
FROM 
    (SELECT *, (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) AS reset_days FROM pg_stat_io) AS i,
    (SELECT sum(writes) AS t_writes FROM pg_stat_io WHERE object = 'relation') AS t,
    (SELECT current_setting('block_size')::numeric AS blk_size) AS b
WHERE 
    writes > 0 AND
    i.object = 'relation'
GROUP BY i.backend_type, reset_days, stats_reset, t_writes
ORDER BY sum(writes) DESC;
