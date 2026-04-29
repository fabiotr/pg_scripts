SELECT 
    row_number() over(order by sum(total_exec_time + total_plan_time) desc) AS "N",
    string_agg(distinct datname,', ')                        AS "DB",
    string_agg(distinct rolname,', ')                        AS "User",
    queryid                                                  AS "QueryID",
    to_char(sum(calls / reset_days),          '999G999G999') AS "Calls/Day", 
    to_char(sum(plans / reset_days),          '999G999G999') AS "Plans/Day", 
    to_char(sum(rows)  / nullif(sum(calls), 0), '999G990D9') AS "Rows/Call",
    --to_char(sum(parallel_workers_to_launchs / reset_days),'999G999G999') AS "Workers Planned/Day",
    --to_char(sum(parallel_workers_launched   / reset_days),'999G999G999') AS "Workers Lunched/Day",
    trunc(sum(total_plan_time)::numeric * 100 / nullif(sum(total_plan_time + total_exec_time)::numeric, 0), 1)  AS "Plan %",
    to_char((sum(total_exec_time) / reset_days)                   * INTERVAL '1 millisecond', 'HH24:MI:SS')     AS "Exec T/Day",
    to_char((sum(total_plan_time) / reset_days)                   * INTERVAL '1 millisecond', 'HH24:MI:SS')     AS "Plan T/Day",
    to_char((sum(total_exec_time + total_plan_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')     AS "Total T/Day",
    trunc(sum(shared_blks_hit)::numeric * 100 / nullif(sum(shared_blks_hit + shared_blks_read)::numeric, 0), 1) AS "S Hit %",
    pg_size_pretty(nullif(trunc(current_setting('block_size')::numeric * sum(shared_blks_read)                   
        / reset_days),0))                                                                                       AS "S Read/Day",
    pg_size_pretty(nullif(trunc(current_setting('block_size')::numeric * sum(temp_blks_read + temp_blks_written) 
        / reset_days),0))                                                                                       AS "Temp/Day",
    to_char((sum(
	shared_blk_read_time + shared_blk_write_time + 
        local_blk_read_time + local_blk_write_time + 
        temp_blk_read_time + temp_blk_write_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS')      AS "IO T/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END                                                     AS query
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid 
    JOIN pg_roles u ON u.oid = s.userid,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
GROUP BY reset_days, queryid, query
ORDER BY sum(total_exec_time + total_plan_time) DESC
LIMIT 20;
