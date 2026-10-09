SELECT                                  
    lpad(row_number() OVER (ORDER BY wal_bytes DESC)::text, 2) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '  ' END AS "N",
    lpad(to_char(wal_bytes * 100 / nullif(sum(wal_bytes) OVER (), 0),'FM99D09'), 6) || '%' AS "WAL %",
    --datname AS "DB",
    userid::regrole AS "User",
    queryid,
    lpad(to_char(calls::numeric        / reset_days::numeric, 'FM999G999G990D0'), 14) AS "Calls/Day",
    lpad(to_char(rows::numeric         / reset_days,            'FM999G999G999'), 12) AS "Rows/Day",
    lpad(to_char(rows::numeric         / calls::numeric,      'FM999G999G990D0'), 14) AS "Rows/Call",
    lpad(to_char(wal_records::numeric  / calls::numeric, 'FM999G990D0'), 10)          AS "Wal/Call",
    lpad(pg_size_pretty(trunc(nullif(wal_bytes::numeric/calls,0))), 11)             AS "WAL Size/Call",
    lpad(to_char(wal_records::numeric/reset_days, 'FM999G999G999'), 12)               AS "WAL Records/Day",
    lpad(to_char(wal_fpi::numeric/reset_days,     'FM9G999G999'), 10)                 AS "WAL FPI/Day", 
    lpad(pg_size_pretty(nullif(wal_bytes::numeric/reset_days,0)), 11)               AS "WAL Size/Day",
    to_char(((total_exec_time + total_plan_time) / reset_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total Time/Day",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    :svp_pgss.pg_stat_statements AS s
    JOIN pg_database AS d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM :svp_pgss.pg_stat_statements_info) AS r
WHERE
    wal_bytes > 0 AND 
    datname = current_database()
ORDER BY wal_bytes DESC
LIMIT 10;
