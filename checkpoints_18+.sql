\x on
SELECT
    to_char(100 * num_timed::NUMERIC  	    / nullif((num_timed + num_requested),0),'990D9') || ' %' AS "Checkpoints timed",
    to_char(100 * num_requested::NUMERIC    / nullif((num_timed + num_requested),0),'990D9') || ' %' AS "Checkpoints requested",
    num_requested - num_done                                                                         AS "requested not done",
    pg_size_pretty((buffers_written * current_setting('block_size')::INTEGER) / (num_timed + num_requested)) AS "Average bytes / Checkpoin",
    '-------' AS "------------------",
    trim(to_char(restartpoints_timed::NUMERIC / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G990D9')) AS "Restartpoints timed     / Day",
    trim(to_char(restartpoints_req::NUMERIC   / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G990D9')) AS "Restartpoints requested / Day",
    trim(to_char(restartpoints_done::NUMERIC  / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G990D9')) AS "Restartpoints done      / Day",
    '-------' AS "------------------",
    pg_size_pretty(trunc((buffers_written * current_setting('block_size')::INTEGER) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))))  AS "Shared buffers / Day",
    pg_size_pretty(trunc((slru_written    * current_setting('block_size')::INTEGER) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))))  AS "SLRU   buffers / Day",
    date_trunc('second',write_time / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND')                  AS "Write time  / Day",
    date_trunc('second',sync_time  / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND')                  AS "Sync  time  / Day",
    '-------' AS "------------------",
    date_trunc('second', current_timestamp - stats_reset)                                                                                            AS "Age"
FROM pg_stat_checkpointer;
\x auto
