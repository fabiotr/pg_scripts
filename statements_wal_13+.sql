SELECT                                  
    row_number() OVER (ORDER BY wal_bytes DESC) || CASE WHEN toplevel = FALSE THEN ' *' ELSE '' END AS "N",
    trim(to_char(wal_bytes * 100 / sum(wal_bytes) OVER (),'99D99') || '%') AS "WAL %",
    --datname AS "DB",
    userid::regrole AS "User",
    queryid,
    to_char(calls::numeric,     '999G999G990D9') AS "Calls",
    to_char(rows::numeric,        '999G999G999') AS "Rows",
    to_char(rows::numeric,      '999G999G990D9') AS "Rows/Call",
    to_char(wal_records::numeric,   '999G990D9') AS "Wal/Call",
    pg_size_pretty(trunc(nullif(wal_bytes::numeric/calls,0))) AS "WAL Size/Call",
    to_char(wal_records::numeric, '999G999G999') AS "WAL Records",
    to_char(wal_fpi::numeric,     '999G999')     AS "WAL FPI", 
    pg_size_pretty(nullif(wal_bytes::numeric,0)) AS "WAL Size",
    to_char((total_exec_time + total_plan_time) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') ||
        CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM
    pg_stat_statements AS s
    JOIN pg_database AS d ON d.oid = s.dbid
WHERE
    wal_bytes > 0 AND 
    datname = current_database()
ORDER BY wal_bytes DESC
LIMIT 10;

\timing on
\set QUIET off
