SELECT
    'WAITING' AS ".",
    '=======' AS ".",
    w.pid || ' | ' || w.state            AS "pid/state",
    w.client_addr || ' | ' || w.usename || ' | ' || w.application_name    AS "ip/user/app",

    to_char(w.query_start,'DD HH24:MI:SS')    || ' | ' || to_char(clock_timestamp() - w.query_start,   'HH24:MI:SS.MS') AS query_start,
    to_char(w.xact_start,'DD HH24:MI:SS')     || ' | ' || to_char(clock_timestamp() - w.xact_start,    'HH24:MI:SS.MS') AS xact_start,
    to_char(w.backend_start,'DD HH24:MI:SS')  || ' | ' || to_char(clock_timestamp() - w.backend_start, 'HH24:MI:SS.MS') AS conn_start,
    --string_agg(pw.locktype,',') AS lock_type,
    --string_agg(pw.mode,',')     AS lock_mode,
    string_agg(pw.relation::regclass::text,', ') AS "table(s)",
    CASE w.state WHEN 'active' THEN w.wait_event_type || ' | ' || w.wait_event 
        ELSE NULL END AS "type/event",
    array_to_string(regexp_split_to_array(substr(w.query,1,200),'\s+'),' ') AS query,
    '' AS ".",
    'LOCKER' AS ".",
    '======' AS ".",
    l.pid || ' | ' || l.state   AS "pid/state",
    l.client_addr || ' | ' || l.usename || ' | ' || l.application_name                   AS "ip/user/app",
    to_char(l.query_start,'DD HH24:MI:SS')    || ' | ' || to_char(clock_timestamp() - l.query_start,   'HH24:MI:SS.MS') AS query_start,
    to_char(l.xact_start,'DD HH24:MI:SS')     || ' | ' || to_char(clock_timestamp() - l.xact_start,    'HH24:MI:SS.MS') AS xact_start,
    to_char(l.backend_start,'DD HH24:MI:SS')  || ' | ' || to_char(clock_timestamp() - l.backend_start, 'HH24:MI:SS.MS') AS conn_start,
    CASE l.state WHEN 'active' THEN l.wait_event_type || ' | ' || l.wait_event 
        ELSE NULL END AS "type/event",
    array_to_string(regexp_split_to_array(substr(l.query,1,200),'\s+'),' ') AS query
  FROM 
        (SELECT pid, unnest(pg_blocking_pids(pid)) as lpid
            FROM pg_stat_activity
            WHERE cardinality(pg_blocking_pids(pid)) > 0) b
    JOIN pg_stat_activity w ON w.pid = b.pid
    JOIN pg_stat_activity l ON l.pid = b.lpid  
    JOIN pg_locks pw        ON w.pid = pw.pid
    LEFT JOIN pg_locks pl        ON l.pid = pl.pid AND pl.database = pw.database AND pl.relation = pw.relation
  GROUP BY 
    w.pid, w.state, w.usename, w.application_name, w.client_addr, w.query_start, w.xact_start, w.backend_start, w.wait_event_type, w.wait_event, w.query,
    l.pid, l.state, l.usename, l.application_name, l.client_addr, l.query_start, l.xact_start, l.backend_start, l.wait_event_type, l.wait_event, l.query
  ORDER BY l.query_start;
