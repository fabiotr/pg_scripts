SELECT
lpad(row_number() over(ORDER BY shared_blks_read + shared_blks_written DESC)::text, 2) || CASE WHEN toplevel = FALSE THEN ' * ' ELSE '   ' END AS "N",
    lpad(to_char((shared_blks_read + shared_blks_written) * 100 / sum(shared_blks_read) OVER (),'FM99D09'), 6) || '%' AS "I/O %",
    --datname AS "DB", 
    userid::regrole AS "User",
    queryid,
    lpad(to_char(calls::numeric / reset_days::numeric, 'FM999G999G990D0'), 14) AS "Calls/Day",
    --to_char(rows::numeric  / reset_days,          'FM999G999G999')   AS "Rows/Day",
    lpad(to_char(rows::numeric  / calls::numeric,      'FM999G990D0'), 10)     AS "Rows/Call",
    --pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_hit)::numeric     / calls),     0)) AS "Hit/Call",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_read)::numeric    / calls),     0)), 11) AS "Reads/Call",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_written)::numeric / calls),     0)), 11) AS "Writes/Call",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_hit)::numeric     / reset_days),0)), 11) AS "Hit/Day",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_read)::numeric    / reset_days),0)), 11) AS "Reads/Day",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_written)::numeric / reset_days),0)), 11) AS "Writes/Day",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_dirtied)::numeric / reset_days),0)), 11) AS "Dirtied/Day",
    trunc(shared_blks_hit::numeric * 100 / nullif((shared_blks_hit + shared_blks_read)::numeric,0),1)  AS "Hit %" ,
    to_char((blk_read_time                     / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Read/Day",
    to_char((blk_write_time                    / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Write/Day",
    to_char((total_exec_time + total_plan_time / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    :svp_pgss.pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM :svp_pgss.pg_stat_statements_info) AS r
WHERE 
    shared_blks_read + shared_blks_written + shared_blks_dirtied > 0 AND
    datname = current_database()
ORDER BY coalesce(shared_blks_read,0) + coalesce(shared_blks_written,0) DESC
LIMIT 10;
