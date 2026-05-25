SELECT 
    schemaname AS "Schema", 
    relname AS "Table", 
    pg_size_pretty(pg_total_relation_size(relid)) AS "Size", 
    pg_size_pretty(pg_table_size(relid) - pg_relation_size(relid,'main')) AS "Toast size",
    --to_char((coalesce(heap_blks_hit,0) + coalesce(heap_blks_read,0) + coalesce(idx_blks_hit,0) + idx_blks_read + coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) + tidx_blks_hit + tidx_blks_read) /
    --    SUM(heap_blks_hit + heap_blks_read + coalesce(idx_blks_hit,0) + coalesce(idx_blks_read,0) + coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) + tidx_blks_hit + tidx_blks_read) OVER(),'FM990D99') || ' %' AS "Avg weight",
    pg_size_pretty(trunc((current_setting('block_size')::bigint * toast_blks_hit)  / reset_days)::bigint) AS "Hit/Day",
    pg_size_pretty(trunc((current_setting('block_size')::bigint * toast_blks_read) / reset_days)::bigint) AS "Read/Day",
    trunc(100 * toast_blks_hit  / sum(toast_blks_hit)  OVER(),1) AS "Hit/Tot %",
    trunc(100 * toast_blks_read / sum(toast_blks_read) OVER(),1) AS "Read/Tot %",
    to_char(CASE toast_blks_hit WHEN 0 THEN 0 ELSE 100 * toast_blks_hit::NUMERIC / (toast_blks_hit + toast_blks_read) END,'FM990D99') AS "Hit %"
FROM 
    pg_statio_all_tables
    JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
WHERE coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) > 0
ORDER BY  toast_blks_read  DESC 
LIMIT 10;
