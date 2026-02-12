SELECT
    to_char(wal_records::NUMERIC        / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'9999G999G990D9')           AS "Records     / Day",
    to_char(wal_fpi::NUMERIC            / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G999G990D9')            AS "FPI         / Day",
    to_char(wal_buffers_full::NUMERIC   / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G999G990D9')            AS "Buffer full / Day",
    to_char(wal_write::NUMERIC          / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G999G990D9')            AS "Writes      / Day",
    to_char(wal_sync::NUMERIC           / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G999G990D9')            AS "Syncs       / Day",
    date_trunc('second', wal_write_time / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND') AS "Write time  / Day",
    date_trunc('second', wal_sync_time  / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) * INTERVAL '1 MIlLISECOND') AS "Sync time   / Day",
    (pg_size_pretty(wal_bytes           / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))))                           AS "Total size  / Day",
    date_trunc('second', current_timestamp - stats_reset)                                                                                AS "Age"
FROM pg_stat_wal;
