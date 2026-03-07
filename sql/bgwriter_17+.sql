WITH stats AS (
    SELECT
        current_setting('block_size')::INTEGER AS block_size,
        EXTRACT(EPOCH FROM (current_timestamp - stats_reset)) / (60*60*24) AS reset_days,
        *
    FROM pg_stat_bgwriter
),
io_stats AS (
    SELECT
        backend_type,
        SUM(writes * op_bytes) AS write_bytes,
        SUM(write_time) AS total_write_time
    FROM pg_stat_io
    WHERE object = 'relation'
    GROUP BY 1
),
io_summary AS (
    SELECT
        SUM(write_bytes) FILTER (WHERE backend_type = 'background writer') AS bg_write_bytes,
        SUM(total_write_time) FILTER (WHERE backend_type = 'background writer') AS bg_write_time,
        SUM(write_bytes) FILTER (WHERE backend_type = 'checkpointer') AS cp_write_bytes,
        SUM(write_bytes) FILTER (WHERE backend_type NOT IN ('background writer', 'checkpointer')) AS backend_write_bytes,
        SUM(write_bytes) AS total_write_bytes
    FROM io_stats
)
SELECT
    pg_size_pretty(trunc((s.buffers_alloc * s.block_size) / s.reset_days)) AS "Bytes allocated      / Day",
    pg_size_pretty(trunc((s.buffers_clean * s.block_size) / s.reset_days)) AS "Bytes clean          / Day",
    trim(to_char(s.maxwritten_clean::NUMERIC / s.reset_days, '999G990D9')) AS "BG stops by maxpages / Day",
    to_char(100 * COALESCE(i.bg_write_bytes, 0)::NUMERIC / NULLIF(i.total_write_bytes, 0), '990D9') || ' %' AS "BG Writer % of Total Writes",
    '-------' AS "------------------",
    pg_size_pretty(trunc(COALESCE(i.cp_write_bytes, 0) / s.reset_days)) AS "Checkpointer Writes  / Day",
    pg_size_pretty(trunc(COALESCE(i.backend_write_bytes, 0) / s.reset_days)) AS "Backend Writes       / Day",
    '-------' AS "------------------",
    date_trunc('second', COALESCE(i.bg_write_time, 0) / s.reset_days * INTERVAL '1 MILLISECOND') AS "BG Write time / Day",
    date_trunc('second', current_timestamp - s.stats_reset) AS "Age"
FROM stats s, io_summary i;
