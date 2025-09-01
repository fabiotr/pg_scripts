SELECT
    count(1) || ' / ' || current_setting('pg_stat_statements.max') || ' / ' || r.dealloc AS "Number of queryes / Max / Lost",
    to_char((sum(total_exec_time)/reset_days) * INTERVAL '1 millisecond' / (sum(calls)/reset_days),'FF6') AS "Avg time (uS)", 
    to_char(sum(calls)/reset_days,'999G999G999') AS "Total calls/Day",
    to_char((sum(total_exec_time)/reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total time/Day",
    CASE WHEN current_setting('track_io_timing')::BOOLEAN = TRUE
        THEN to_char(((sum(temp_blk_read_time + temp_blk_write_time))/reset_days) * INTERVAL '1 millisecond','HH24:MI:SS')
        ELSE NULL END AS "Temp time/Day",
        pg_size_pretty(((sum(temp_blks_read + temp_blks_written))/reset_days) * current_setting('block_size')::integer) AS "Total Temp/Day",
        to_char(current_timestamp - stats_reset, 'DD-MM-YY hh24:mi') AS "Time since last Reset"
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT dealloc, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days, stats_reset FROM pg_stat_statements_info) AS r
WHERE datname = current_database()
GROUP BY r.reset_days, r.stats_reset, r.dealloc;
