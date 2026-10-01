SELECT
    lpad(to_char(60 * 60 * 24 * archived_count /
        EXTRACT (epoch FROM CURRENT_TIMESTAMP - stats_reset),'FM999G990'), 8)                                                            AS "Count  / day",
    lpad(to_char(failed_count::NUMERIC * 60 * 60 * 24 * 30 / (EXTRACT (epoch FROM CURRENT_TIMESTAMP - stats_reset))::BIGINT,'FM99990D99'), 9) AS "Failed / month",
    to_char(last_failed_time, 'YYYY-MM-DD')                                                                                          AS "Last Failed",
    date_trunc('second', CURRENT_TIMESTAMP - stats_reset)                                                                            AS "Age"
FROM pg_stat_archiver;
