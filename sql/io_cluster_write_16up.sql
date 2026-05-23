SELECT
    backend_type,
    lpad(round(sum(writes) * 100 / t_writes,1) || ' %',6)                               AS "Write",
    lpad(pg_size_pretty(round(coalesce(sum(writes)  * op_bytes / reset_days, 0))),7)    AS "Write/Day",
    lpad(pg_size_pretty(round(coalesce(sum(extends) * op_bytes / reset_days, 0))),7)    AS "Extend/Day",
    to_char(coalesce(sum(write_time),      0) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Write T/Day",
    to_char(coalesce(sum(extend_time),     0) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Extend T/Day",
    to_char(coalesce(sum(writeback_time ), 0) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Writeback T/Day",
    to_char(coalesce(sum(fsync_time ),     0) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Fsync T/Day",
    lpad(round(100.0 * sum(coalesce(writeback_time,0) + coalesce(fsync_time,0))::numeric /
        nullif(sum(coalesce(write_time,0) + coalesce(extend_time,0) + coalesce(writeback_time,0) + coalesce(fsync_time,0)),0)::numeric,1)
        || ' %',6) AS "Physical Write T",
    CASE backend_type
        WHEN  'background writer' THEN 
            CASE
                WHEN sum(writes) * 100 / t_writes = 0               THEN '🔴 Critical (inactive)'
                WHEN sum(writes) * 100 / t_writes > 60              THEN '🟠 Warning  (too high)'
                WHEN sum(writes) * 100 / t_writes BETWEEN 40 AND 60 THEN '🟡 Atention (high)'
                WHEN sum(writes) * 100 / t_writes < 10              THEN '🟡 Atention (low)'
                WHEN sum(writes) * 100 / t_writes BETWEEN 10 AND 40 THEN '✅ OK'
            END
        WHEN 'checkpointer' THEN 
            CASE 
                WHEN sum(writes) * 100 / t_writes = 0               THEN '🔴 Critical (inactive)'
                WHEN sum(writes) * 100 / t_writes < 30              THEN '🟠 Warning  (too low)'
                WHEN sum(writes) * 100 / t_writes > 90              THEN '🟠 Warning  (too high)'
                WHEN sum(writes) * 100 / t_writes BETWEEN 30 AND 50 THEN '🟡 Atention (low)'
                WHEN sum(writes) * 100 / t_writes BETWEEN 80 AND 90 THEN '🟡 Atention (high)'
                WHEN sum(writes) * 100 / t_writes BETWEEN 50 AND 80 THEN '✅ OK'
            END
        WHEN 'client backend' THEN
            CASE
                WHEN sum(writes) * 100 / t_writes < 2               THEN '🔵 Nice'
                WHEN sum(writes) * 100 / t_writes BETWEEN 2  AND 10 THEN '✅ OK'
                WHEN sum(writes) * 100 / t_writes BETWEEN 10 AND 15 THEN '🟡 Atention (high)'
                WHEN sum(writes) * 100 / t_writes BETWEEN 15 AND 20 THEN '🟠 Warning  (too high)'
                WHEN sum(writes) * 100 / t_writes > 20              THEN '🔴 Critical (high latency)'
            END
        WHEN 'autovacuum worker' THEN
            CASE
                WHEN sum(writes) * 100 / t_writes < 5               THEN '🔵 Nice'
                WHEN sum(writes) * 100 / t_writes BETWEEN 5  AND 10 THEN '✅ OK'
                WHEN sum(writes) * 100 / t_writes BETWEEN 10 AND 20 THEN '🟡 Atention (high)'
                WHEN sum(writes) * 100 / t_writes BETWEEN 20 AND 30 THEN '🟠 Warning  (too high)'
                WHEN sum(writes) * 100 / t_writes > 30              THEN '🔴 Critical (high latency)'
            END
        ELSE                                                             'N/A'
        END AS "Write status",
    CASE 
        WHEN 100.0 * sum(coalesce(writeback_time,0) + coalesce(fsync_time,0))::numeric /
            nullif(sum(coalesce(write_time,0) + coalesce(extend_time,0) + coalesce(writeback_time,0) + coalesce(fsync_time,0)),0)
                                                < 20                THEN '🔵 Nice'
        WHEN 100.0 * sum(coalesce(writeback_time,0) + coalesce(fsync_time,0))::numeric /
            nullif(sum(coalesce(write_time,0) + coalesce(extend_time,0) + coalesce(writeback_time,0) + coalesce(fsync_time,0)),0)
                                                BETWEEN 20 AND 40   THEN '✅ OK'
        WHEN 100.0 * sum(coalesce(writeback_time,0) + coalesce(fsync_time,0))::numeric /
            nullif(sum(coalesce(write_time,0) + coalesce(extend_time,0) + coalesce(writeback_time,0) + coalesce(fsync_time,0)),0)
                                                BETWEEN 40 AND 60   THEN '🟡 Atention (high)'
        WHEN 100.0 * sum(coalesce(writeback_time,0) + coalesce(fsync_time,0))::numeric /
            nullif(sum(coalesce(write_time,0) + coalesce(extend_time,0) + coalesce(writeback_time,0) + coalesce(fsync_time,0)),0)
                                                BETWEEN 60 AND 70   THEN '🟠 Warning  (too high)'
        WHEN 100.0 * sum(coalesce(writeback_time,0) + coalesce(fsync_time,0))::numeric /
            nullif(sum(coalesce(write_time,0) + coalesce(extend_time,0) + coalesce(writeback_time,0) + coalesce(fsync_time,0)),0)
                                                > 70                THEN '🟠 Warning  (too high)'
        END AS "Physical Write status"
FROM
    (SELECT *, (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) AS reset_days FROM pg_stat_io) AS i,
    (SELECT sum(writes) AS t_writes FROM pg_stat_io WHERE object = 'relation') AS t,
    (SELECT current_setting('block_size')::numeric AS blk_size) AS b
WHERE
    writes > 0 AND
    i.object = 'relation'
GROUP BY i.backend_type, reset_days, stats_reset, t_writes, op_bytes
ORDER BY sum(writes) DESC;
