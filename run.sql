SELECT
    pid,
    client_addr,
    to_char(query_start,'HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - query_start),'MI:SS') AS query_start,
    to_char(xact_start ,'HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - xact_start ),'MI:SS') AS xact_start,
    state,
    coalesce(wait_event_type, 'NULL') || ' - ' || coalesce(wait_event, 'NULL') AS "PID - WAITING",
    array_to_string(regexp_split_to_array(substr(query,1,400),'\s+'),' ') AS query
FROM pg_stat_activity
WHERE
    state != 'idle' AND
    pid != pg_backend_pid() AND
    backend_type = 'client backend'
ORDER BY query_start;
