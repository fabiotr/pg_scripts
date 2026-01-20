SELECT
    pg_size_pretty(trunc((buffers_alloc * current_setting('block_size')::INTEGER) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))))       AS "Bytes allocated      / Day",
    pg_size_pretty(trunc((buffers_clean * current_setting('block_size')::INTEGER) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24))))       AS "Bytes clean          / Day",
    trim(to_char(maxwritten_clean::NUMERIC                                  / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)),'999G990D9')) AS "BG stops by maxpages / Day",
    date_trunc('second', current_timestamp - stats_reset)                                                                                                      AS "Age"
FROM pg_stat_bgwriter;
