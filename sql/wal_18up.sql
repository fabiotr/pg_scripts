SELECT
    lpad(to_char(wal_records::NUMERIC        / (EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset) / (60*60*24)),'FM9999G999G990D0'), 15) AS "Records     / Day",
    lpad(to_char(wal_fpi::NUMERIC            / (EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset) / (60*60*24)),'FM999G999G990D0'), 14)  AS "FPI         / Day",
    lpad(to_char(wal_buffers_full::NUMERIC   / (EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset) / (60*60*24)),'FM999G999G990D0'), 14)  AS "Buffer full / Day",
    (lpad(pg_size_pretty(wal_bytes           / (EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset) / (60*60*24))), 11))                   AS "Total size  / Day",
    date_trunc('second', CURRENT_TIMESTAMP - stats_reset)                                                                        AS "Age"
FROM pg_stat_wal;
