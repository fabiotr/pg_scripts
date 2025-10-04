SELECT
    row_number() over(order by local_blks_read + local_blks_written + local_blks_dirtied desc) "N",
    trim(to_char(local_blks_read + local_blks_written + local_blks_dirtied * 100 / sum(nullif(local_blks_read + local_blks_written + local_blks_dirtied,0)) OVER (),'99D99') || '%') AS "local_%",
    datname AS "DB", userid::regrole AS "User",
    queryid,
    to_char(calls::numeric,'999G999G990D9') AS "Calls",
    --to_char((rows),'999G999G999') AS "Rows/Day",
    --to_char(rows::numeric/calls::numeric,'999G990D9') AS "Rows/Call",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_read)::numeric),   0)) AS "Read",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_written)::numeric),0)) AS "Written",
    pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_dirtied)::numeric),0)) AS "Dirtied",
    trunc(shared_blks_hit::numeric * 100 / nullif((shared_blks_hit + shared_blks_read)::numeric,0),1) AS "Hit %" ,
    to_char((total_exec_time + total_plan_time) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
WHERE 
    local_blks_read + local_blks_written + local_blks_dirtied > 0 AND 	
    datname = current_database()
ORDER BY local_blks_read + local_blks_written + local_blks_dirtied DESC
LIMIT 20;
\timing on
\set QUIET off
