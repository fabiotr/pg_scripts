SELECT
    lpad(to_char(100 * num_timed::numeric        / nullif((num_timed + num_requested),0),'FM990D0') || ' %',8) AS "Timed",
    lpad(to_char(100 * num_requested::numeric    / nullif((num_timed + num_requested),0),'FM990D0') || ' %',8) AS "Requested",
    lpad(pg_size_pretty((buffers_written * current_setting('block_size')::numeric) / 
        nullif(coalesce(num_timed,0) + coalesce(num_requested,0),0)::numeric),8)                               AS "Avg size",
    '--------' AS "-----------------------------",
    lpad(to_char(restartpoints_timed::numeric / reset_days,'FM9G990D0'),8)                          AS "Restartpoints timed     / Day",
    lpad(to_char(restartpoints_req::numeric   / reset_days,'FM9G990D0'),8)                          AS "Restartpoints requested / Day",
    lpad(to_char(restartpoints_done::numeric  / reset_days,'FM9G990D0'),8)                          AS "Restartpoints done      / Day",
    '--------' AS "-----------------------------",
    lpad(pg_size_pretty(round((buffers_written * current_setting('block_size')::numeric) / reset_days)),8) AS "Shared / Day",
    date_trunc('second',write_time / reset_days * INTERVAL '1 MIlLISECOND')                         AS "Write time  / Day",
    date_trunc('second',sync_time  / reset_days * INTERVAL '1 MIlLISECOND')                         AS "Sync  time  / Day",
    '--------' AS "-----------------------------",
    date_trunc('second', current_timestamp - stats_reset)                                           AS "Age"
FROM (SELECT *, (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) AS reset_days FROM pg_stat_checkpointer) AS c;
