SELECT
    row_number() over(order by total_time desc) "#",
    trim(to_char(total_time*100/sum(total_time) OVER (),'99D99') || '%') AS "load_%",
    datname db, --rolname,
    trim(to_char(calls, '999G999G999G999G999')) AS calls,
    trim(to_char(rows , '999G999G999G999G999')) AS rows,
    --to_char(min_time        * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    --to_char(max_time        * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(total_time / calls * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char(total_time      * INTERVAL '1 millisecond', 'HH24:MI:SS') AS total,
    to_char(blk_read_time   * INTERVAL '1 millisecond', 'HH24:MI:SS') AS read_time,
    to_char(blk_write_time  * INTERVAL '1 millisecond', 'HH24:MI:SS') AS write_time,
    pg_size_pretty(shared_blks_hit   * (pg_control_init()).database_block_size) AS shared_hit,
    pg_size_pretty(shared_blks_read  * (pg_control_init()).database_block_size) AS shared_read,
    pg_size_pretty(local_blks_hit    * (pg_control_init()).database_block_size) AS local_hit,
    pg_size_pretty(local_blks_read   * (pg_control_init()).database_block_size) AS local_read,
    pg_size_pretty(temp_blks_read    * (pg_control_init()).database_block_size) AS temp_read,
    pg_size_pretty(temp_blks_written * (pg_control_init()).database_block_size) AS temp_written,
    array_to_string(regexp_split_to_array(substr(query,1,5000),'\s+'),' ') AS query
FROM
    pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
--    JOIN pg_authid u ON u.oid = s.userid
WHERE datname = current_database()
ORDER BY total_time DESC
LIMIT 5;
