SELECT
    row_number() over(ORDER BY local_blks_read + local_blks_written + local_blks_dirtied DESC) "N",
    lpad(to_char((local_blks_read + local_blks_written + local_blks_dirtied) * 100 / nullif(sum(local_blks_read + local_blks_written + local_blks_dirtied) OVER (), 0),'FM99D09'), 6) || '%' AS "local_%",
    datname AS "DB", userid::regrole AS "User",
    queryid,
    lpad(to_char(calls::numeric/reset_days::numeric,'FM999G999G990D0'), 14) AS "Calls/Day",
    --to_char((rows/reset_days),'FM999G999G999') AS "Rows/Day",
    --to_char(rows::numeric/calls::numeric,'FM999G990D0') AS "Rows/Call",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_read)::numeric    / reset_days),0)), 11) AS "Read/Day",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_written)::numeric / reset_days),0)), 11) AS "Written/Day",
    lpad(pg_size_pretty(nullif(trunc((current_setting('block_size')::numeric * local_blks_dirtied)::numeric / reset_days),0)), 11) AS "Dirtied/Day",
    trunc(shared_blks_hit::numeric * 100 / nullif((shared_blks_hit + shared_blks_read)::numeric,0),1) AS "Hit %" ,
    to_char(((total_exec_time + total_plan_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    :svp_pgss.pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM :svp_pgss.pg_stat_statements_info) AS r
WHERE 
    local_blks_read + local_blks_written + local_blks_dirtied > 0 	
    --datname = current_database()
ORDER BY local_blks_read + local_blks_written + local_blks_dirtied DESC
LIMIT 20;
