-- When Maxwritten is hight, you need to increase the bgwriter_lru_maxpages parameter
SELECT
    lpad(pg_size_pretty(round((buffers_alloc * current_setting('block_size')::INTEGER) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)))),7) AS "Allocated / Day",
    lpad(pg_size_pretty(round((buffers_clean * current_setting('block_size')::INTEGER) / (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)))),7) AS "Clean     / Day",
    lpad(coalesce(round(100.0 * maxwritten_clean / (nullif(buffers_clean,0) / current_setting('bgwriter_lru_maxpages')::numeric),1),0) || ' %',7)                AS "Max written",
    CASE 
        WHEN 100.0 * maxwritten_clean / (nullif(buffers_clean,0) / current_setting('bgwriter_lru_maxpages')::numeric) < 10              THEN ' ✅ OK'
        WHEN 100.0 * maxwritten_clean / (nullif(buffers_clean,0) / current_setting('bgwriter_lru_maxpages')::numeric) BETWEEN 10 AND 25 THEN ' 🟡 Atention'
        WHEN 100.0 * maxwritten_clean / (nullif(buffers_clean,0) / current_setting('bgwriter_lru_maxpages')::numeric) BETWEEN 25 AND 50 THEN ' 🟠 Warning'
        ELSE                                                                                                                                 ' 🔴 Critic'
        END AS "Max written status",
    date_trunc('second', current_timestamp - stats_reset)                                                                                                        AS "Age"
FROM pg_stat_bgwriter;
