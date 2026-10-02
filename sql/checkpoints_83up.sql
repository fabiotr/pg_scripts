SELECT
    lpad(to_char(100 * checkpoints_timed::NUMERIC  / nullif((checkpoints_timed + checkpoints_req),0),'FM990D0'), 6) || ' %' AS "Checkpoints timed",
    lpad(to_char(100 * checkpoints_req::NUMERIC    / nullif((checkpoints_timed + checkpoints_req),0),'FM990D0'), 6) || ' %' AS "Checkpoints req",
    '-------' AS "------------------",
    lpad(to_char(100 * buffers_checkpoint::NUMERIC / nullif((buffers_checkpoint + buffers_clean + buffers_backend),0),'FM990D0'), 6) || ' %' AS "Written checkpoint",
    lpad(to_char(100 * buffers_backend::NUMERIC    / nullif((buffers_checkpoint + buffers_clean + buffers_backend),0),'FM990D0'), 6) || ' %' AS "Written backend",
    lpad(to_char(100 * buffers_clean::NUMERIC      / nullif((buffers_checkpoint + buffers_clean + buffers_backend),0),'FM990D0'), 6) || ' %' AS "Written clean",
    '-------' AS "------------------",
    lpad(pg_size_pretty((buffers_checkpoint + buffers_clean + buffers_backend) * current_setting('block_size')::INTEGER), 11) AS "Size"
FROM pg_stat_bgwriter;
