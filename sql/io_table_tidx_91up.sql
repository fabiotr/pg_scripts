SELECT 
    schemaname AS "Schema", 
    relname AS "Table", 
    pg_size_pretty(pg_total_relation_size(relid)) AS "Size", 
    pg_size_pretty(trunc((current_setting('block_size')::bigint * tidx_blks_hit)  / reset_days)::bigint) AS "Hit/Day",
    pg_size_pretty(trunc((current_setting('block_size')::bigint * tidx_blks_read) / reset_days)::bigint) AS "Read/Day",
    trunc(100 * tidx_blks_hit  / sum(tidx_blks_hit)  OVER(),1) AS "Hit/Tot %",
    trunc(100 * tidx_blks_read / sum(tidx_blks_read) OVER(),1) AS "Read/Tot %",
    --to_char(CASE tidx_blks_hit  WHEN 0 THEN 0 ELSE 100 * (tidx_blks_hit  + tidx_blks_read)  / (SUM (tidx_blks_hit  + tidx_blks_read)  OVER ()) END,'FM990D99') || ' %' AS "Tidx  weight",
    to_char(CASE tidx_blks_hit  WHEN 0 THEN 0 ELSE 100 * tidx_blks_hit::NUMERIC  / (tidx_blks_hit  + tidx_blks_read)  END,'FM990D99') AS "Hit %"
FROM 
    pg_statio_all_tables
    JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
WHERE coalesce(tidx_blks_hit,0) + coalesce(tidx_blks_read,0) > 0
ORDER BY  tidx_blks_read DESC 
LIMIT 10;
