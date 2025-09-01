SELECT
    to_char(60 * 60 * 24 * archived_count /
        EXTRACT (EPOCH FROM current_timestamp - stats_reset),'999G990') AS "Count  / day",
    to_char(failed_count::NUMERIC * 60 * 60 * 24 * 30 / (EXTRACT (EPOCH FROM current_timestamp - stats_reset))::BIGINT,'99990D99') AS "Failed / month"
FROM pg_stat_archiver;
