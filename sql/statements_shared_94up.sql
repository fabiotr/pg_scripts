SELECT
lpad(row_number() over(ORDER BY shared_blks_read + shared_blks_written DESC)::text, 2) AS "N",
    lpad(to_char((shared_blks_read + shared_blks_written) * 100 / nullif(sum(shared_blks_read + shared_blks_written) OVER (), 0),'FM99D09'), 6) || '%' AS "I/O %",
    --datname AS "DB", 
    r.rolname AS "User",
    queryid,
    lpad(to_char(calls::numeric, 'FM999G999G990D0'), 14) AS "Calls",
    --to_char(rows::numeric,    'FM999G999G999')   AS "Rows/Day",
    lpad(to_char(rows::numeric  / calls::numeric, 'FM999G990D0'), 10)     AS "Rows/Call",
    --pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_hit)::numeric     / calls),     0)) AS "Hit/Call",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_read)::numeric    / calls), 0)), 11) AS "Reads/Call",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_written)::numeric / calls), 0)), 11) AS "Writes/Call",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_hit)::numeric),             0)), 11) AS "Hit",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_read)::numeric),            0)), 11) AS "Reads",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_written)::numeric),         0)), 11) AS "Writes",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * shared_blks_dirtied)::numeric),         0)), 11) AS "Dirtied",
    trunc(shared_blks_hit::numeric * 100 / nullif((shared_blks_hit + shared_blks_read)::numeric, 0),1) AS "Hit %" ,
    to_char(blk_read_time                       * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Read",
    to_char(blk_write_time                      * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Write",
    to_char(total_time * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    :svp_pgss.pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
    JOIN pg_roles r ON r.oid = s.userid
WHERE 
    shared_blks_read + shared_blks_written + shared_blks_dirtied > 0 AND
    datname = current_database()
ORDER BY shared_blks_read + shared_blks_written DESC
LIMIT 10;
