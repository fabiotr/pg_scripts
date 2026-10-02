SELECT                                  
    lpad(row_number() OVER (ORDER BY wal_bytes DESC)::text, 2) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '  ' END AS "N",
    lpad(to_char(wal_bytes * 100 / sum(wal_bytes) OVER (),'FM90D00'), 6) || '%' AS "WAL %",
    --datname AS "DB",
    userid::regrole AS "User",
    queryid,
    lpad(to_char(calls::numeric        / since_days::numeric, 'FM999G999G990D0'), 14) AS "Calls/Day",
    lpad(to_char(rows::numeric         / since_days,            'FM999G999G999'), 12) AS "Records/Day",
    lpad(to_char(rows::numeric         / calls::numeric,      'FM999G999G990D0'), 14) AS "Records/Call",
    lpad(to_char(wal_records::numeric  / calls::numeric, 'FM999G990D0'), 10)          AS "Wal/Call",
    lpad(pg_size_pretty(trunc(nullif(wal_bytes::numeric/calls,0))), 11)               AS "WAL Size/Call",
    lpad(to_char(wal_records::numeric/since_days,  'FM999G999G999'), 12)              AS "WAL Records/Day",
    lpad(to_char(wal_fpi::numeric/since_days,          'FM9G999G999'), 10)            AS "WAL FPI/Day", 
    lpad(to_char(wal_buffers_full::numeric/since_days, 'FM999G999'), 8)              AS "WAL full buffers/Day", 
    lpad(pg_size_pretty(nullif(wal_bytes::numeric/since_days,0)), 11)                 AS "WAL Size/Day",
    to_char((total_exec_time + total_plan_time / since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total Time/Day",
    CASE WHEN stats_since - stats_reset < (CURRENT_TIMESTAMP - stats_reset) / 50 THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END AS "Stats",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    (SELECT *, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_since)::numeric/(60*60*24) AS since_days FROM pg_stat_statements) AS s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(epoch FROM CURRENT_TIMESTAMP - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE
    wal_bytes > 0 AND 
    datname = current_database()
ORDER BY wal_bytes DESC
LIMIT 10;
