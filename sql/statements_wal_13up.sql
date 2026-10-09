SELECT                                  
    lpad(row_number() OVER (ORDER BY wal_bytes DESC)::text, 2) AS "N",
    lpad(to_char(wal_bytes * 100 / nullif(sum(wal_bytes) OVER (), 0),'FM99D09'), 6) || '%' AS "WAL %",
    --datname AS "DB",
    userid::regrole AS "User",
    queryid,
    lpad(to_char(calls::numeric,     'FM999G999G990D0'), 14) AS "Calls",
    lpad(to_char(rows::numeric,        'FM999G999G999'), 12) AS "Rows",
    lpad(to_char(rows::numeric / nullif(calls, 0), 'FM999G999G990D0'), 14) AS "Rows/Call",
    lpad(to_char(wal_records::numeric / nullif(calls, 0), 'FM999G990D0'), 10) AS "Wal/Call",
    lpad(pg_size_pretty(trunc(nullif(wal_bytes::numeric/calls,0))), 11) AS "WAL Size/Call",
    lpad(to_char(wal_records::numeric, 'FM999G999G999'), 12) AS "WAL Records",
    lpad(to_char(wal_fpi::numeric,     'FM9G999G999'), 10)   AS "WAL FPI", 
    lpad(pg_size_pretty(nullif(wal_bytes::numeric,0)), 11) AS "WAL Size",
    to_char((total_exec_time + total_plan_time) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total",
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    :svp_pgss.pg_stat_statements AS s
    JOIN pg_database AS d ON d.oid = s.dbid
WHERE
    wal_bytes > 0 AND 
    datname = current_database()
ORDER BY wal_bytes DESC
LIMIT 10;
