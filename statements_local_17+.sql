SELECT
row_number() over(order by local_blks_read + local_blks_written DESC) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '' END AS "N",
    trim(to_char((local_blks_read + local_blks_written) * 100 / sum(local_blks_read + local_blks_written) OVER (),'99D99') || '%') AS "I/O %",
    --datname AS "DB", 
    userid::regrole AS "User",
    queryid,
    calls,
    to_char(calls::numeric / since_days::numeric, '999G999G990D9') AS "Calls/Day",
    --to_char(rows::numeric  / since_days,          '999G999G999')   AS "Rows/Day",
    to_char(rows::numeric  / calls::numeric,      '999G990D9')     AS "Rows/Call",
    --pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_hit)::numeric     / calls),     0)) AS "Hit/Call",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_read)::numeric    / calls),     0)) AS "Reads/Call",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_written)::numeric / calls),     0)) AS "Writes/Call",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_hit)::numeric     / since_days),0)) AS "Hit/Day",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_read)::numeric    / since_days),0)) AS "Reads/Day",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_written)::numeric / since_days),0)) AS "Writes/Day",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_dirtied)::numeric / since_days),0)) AS "Dirtied/Day",
    trunc(local_blks_hit::numeric * 100 / nullif((local_blks_hit + local_blks_read)::numeric,0),1) AS "Hit %" ,
    to_char((local_blk_read_time                     / since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Read/Day",
    to_char((local_blk_write_time                    / since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Write/Day",
    to_char((total_exec_time + total_plan_time       / since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total/Day",
    CASE WHEN stats_since - stats_reset < (current_timestamp - stats_reset) / 50 THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END AS "Stats",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    (SELECT *, EXTRACT(EPOCH FROM current_timestamp - stats_since)::numeric/(60*60*24) AS since_days FROM pg_stat_statements) AS s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE 
    local_blks_read + local_blks_written + local_blks_dirtied > 0 AND
    datname = current_database()
ORDER BY local_blks_read + local_blks_written DESC
LIMIT 10;
\timing on
\set QUIET off
