SELECT
    to_char(wal_records::NUMERIC        / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'9999G999G990D9')           AS "Records     / Day",
    to_char(wal_fpi::NUMERIC            / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G999G990D9')            AS "FPI         / Day",
    to_char(wal_buffers_full::NUMERIC   / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G999G990D9')            AS "Buffer full / Day",
    (pg_size_pretty(wal_bytes           / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))))                           AS "Total size  / Day",
    date_trunc('second', current_timestamp - stats_reset)                                                                                AS "Age"
FROM pg_stat_wal;
