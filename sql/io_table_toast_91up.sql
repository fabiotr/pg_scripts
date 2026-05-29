SELECT 
    schemaname AS "Schema", 
    relname AS "Table", 
    lpad(pg_size_pretty(pg_total_relation_size(relid)),7) AS "Size", 
    lpad(pg_size_pretty(pg_table_size(relid) - pg_relation_size(relid,'main')),7) AS "Toast size",
    lpad(pg_size_pretty(round((current_setting('block_size')::bigint * toast_blks_hit)  / reset_days)::bigint),7) AS "Hit/Day",
    lpad(pg_size_pretty(round((current_setting('block_size')::bigint * toast_blks_read) / reset_days)::bigint),7) AS "Read/Day",
    round(100 * toast_blks_hit  / sum(toast_blks_hit)  OVER(),1) AS "Hit/Tot %",
    round(100 * toast_blks_read / sum(toast_blks_read) OVER(),1) AS "Read/Tot %",
    lpad(to_char(CASE toast_blks_hit WHEN 0 THEN 0 ELSE 100 * toast_blks_hit::NUMERIC / (toast_blks_hit + toast_blks_read) END,'FM990D0'),5) AS "Hit %"
FROM 
    pg_statio_all_tables
    JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
WHERE coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) > 0
ORDER BY  toast_blks_read  DESC 
LIMIT 10;
