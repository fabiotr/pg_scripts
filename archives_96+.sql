SELECT
    to_char(60 * 60 * 24 * archived_count /
        EXTRACT (EPOCH FROM current_timestamp - stats_reset),'999G990') AS "Count  / day",
    pg_size_pretty(60 * 60 * 24 * (((archived_count) * (pg_control_init()).bytes_per_wal_segment) / 
        (EXTRACT (EPOCH FROM current_timestamp - stats_reset))::BIGINT)) AS "Size   / day",
    to_char(failed_count::NUMERIC * 60 * 60 * 24 * 30 / (EXTRACT (EPOCH FROM current_timestamp - stats_reset))::BIGINT,'99990D99') AS "Failed / month"
FROM pg_stat_archiver;
