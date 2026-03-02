SELECT
    to_char(60 * 60 * 24 * archived_count /
        EXTRACT (EPOCH FROM current_timestamp - stats_reset),'999G990')                                                            AS "Count  / day",
    to_char(failed_count::NUMERIC * 60 * 60 * 24 * 30 / (EXTRACT (EPOCH FROM current_timestamp - stats_reset))::BIGINT,'99990D99') AS "Failed / month",
    to_char(last_failed_time, 'YYYY-MM-DD')                                                                                        AS "Last Failed",
    date_trunc('second', current_timestamp - stats_reset)                                                                          AS "Age"
FROM pg_stat_archiver;
