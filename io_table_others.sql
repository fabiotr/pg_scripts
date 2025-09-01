SELECT schemaname, relname, 
    pg_size_pretty(pg_total_relation_size(relid)) AS "Size", 
    pg_size_pretty(pg_table_size(relid) - pg_relation_size(relid,'main')) AS "Toast size",
    --to_char((coalesce(heap_blks_hit,0) + coalesce(heap_blks_read,0) + coalesce(idx_blks_hit,0) + idx_blks_read + coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) + tidx_blks_hit + tidx_blks_read) /
    --    SUM(heap_blks_hit + heap_blks_read + coalesce(idx_blks_hit,0) + coalesce(idx_blks_read,0) + coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) + tidx_blks_hit + tidx_blks_read) OVER(),'990D99') || ' %' AS "Avg weight",
    pg_size_pretty(trunc((current_setting('block_size')::bigint * toast_blks_hit)  / reset_days)) AS "Toast Hit/Day",
    pg_size_pretty(trunc((current_setting('block_size')::bigint * toast_blks_read) / reset_days)) AS "Toast Read/Day",
    trunc(100 * toast_blks_hit  / sum(toast_blks_hit)  OVER(),1) AS "Toast Hit/Tot %",
    trunc(100 * toast_blks_read / sum(toast_blks_read) OVER(),1) AS "Toast Read/Tot %",
    to_char(CASE toast_blks_hit WHEN 0 THEN 0 ELSE 100 * toast_blks_hit::NUMERIC / (toast_blks_hit + toast_blks_read) END,'990D99') AS "Toast hit %",
    pg_size_pretty(trunc((current_setting('block_size')::bigint * tidx_blks_hit)  / reset_days)) AS "Tidx Hit/Day",
    pg_size_pretty(trunc((current_setting('block_size')::bigint * tidx_blks_read) / reset_days)) AS "Tidx Read/Day",
    trunc(100 * tidx_blks_hit  / sum(tidx_blks_hit)  OVER(),1) AS "Tidx Hit/Tot %",
    trunc(100 * tidx_blks_read / sum(tidx_blks_read) OVER(),1) AS "Tidx Read/Tot %",
    --to_char(CASE tidx_blks_hit  WHEN 0 THEN 0 ELSE 100 * (tidx_blks_hit  + tidx_blks_read)  / (SUM (tidx_blks_hit  + tidx_blks_read)  OVER ()) END,'990D99') || ' %' AS "Tidx  weight",
    to_char(CASE tidx_blks_hit  WHEN 0 THEN 0 ELSE 100 * tidx_blks_hit::NUMERIC  / (tidx_blks_hit  + tidx_blks_read)  END,'990D99') AS "Tidx  hit %"
FROM 
    pg_statio_all_tables
    JOIN (SELECT datname, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_database) d ON d.datname = current_database()
ORDER BY  coalesce(toast_blks_hit,0) + coalesce(toast_blks_read,0) + tidx_blks_hit + tidx_blks_read DESC NULLS LAST
--ORDER BY  heap_blks_hit  + heap_blks_read DESC NULLS LAST
--ORDER BY  toast_blks_hit  + toast_blks_read DESC NULLS LAST
--ORDER BY  tidx_blks_hit  + tidx_blks_read DESC NULLS LAST
LIMIT 10;
