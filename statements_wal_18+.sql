SELECT                                  
    row_number() OVER (ORDER BY wal_bytes DESC) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '' END AS "N",
    trim(to_char(wal_bytes * 100 / sum(wal_bytes) OVER (),'99D99') || '%') AS "WAL %",
    --datname AS "DB",
    userid::regrole AS "User",
    queryid,
    to_char(calls::numeric        / since_days::numeric, '999G999G990D9') AS "Calls/Day",
    to_char(rows::numeric         / since_days,            '999G999G999') AS "Records/Day",
    to_char(rows::numeric         / calls::numeric,      '999G999G990D9') AS "Records/Call",
    to_char(wal_records::numeric  / calls::numeric, '999G990D9')          AS "Wal/Call",
    pg_size_pretty(trunc(nullif(wal_bytes::numeric/calls,0)))             AS "WAL Size/Call",
    to_char(wal_records::numeric/since_days,  '999G999G999')              AS "WAL Records/Day",
    to_char(wal_fpi::numeric/since_days,          '999G999')              AS "WAL FPI/Day", 
    to_char(wal_buffers_full::numeric/since_days, '999G999')              AS "WAL full buffers/Day", 
    pg_size_pretty(nullif(wal_bytes::numeric/since_days,0))               AS "WAL Size/Day",
    to_char((total_exec_time + total_plan_time / since_days) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total Time/Day",
    CASE WHEN stats_since - stats_reset < (current_timestamp - stats_reset) / 50 THEN NULL ELSE to_char(stats_since, 'YYYY-MM-DD HH24:MI') END AS "Stats",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    (SELECT *, EXTRACT(EPOCH FROM current_timestamp - stats_since)::numeric/(60*60*24) AS since_days FROM pg_stat_statements) AS s
    JOIN pg_database d ON d.oid = s.dbid,
    (SELECT stats_reset, EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days FROM pg_stat_statements_info) AS r
WHERE
    wal_bytes > 0 AND 
    datname = current_database()
ORDER BY wal_bytes DESC
LIMIT 10;

\timing on
\set QUIET off
