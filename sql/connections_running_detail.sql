SELECT
    pid::text || ' / ' || state                                                                                             AS "PID / Status",
    usename || ' / ' || host(client_addr)                                                                                   AS "User / IP",
    datname || ' / ' || substr(application_name, 1, 50) || CASE WHEN length(application_name) > 50 THEN '...' ELSE '' END   AS "DB / APP",
    coalesce(leader_pid::varchar,'') || ' /  ' || coalesce(array_to_string(pg_blocking_pids(pid),','),'')                   AS "Leader/Blocker", 
    to_char(backend_start ,'DD HH24:MI:SS') || ' / ' || to_char(date_trunc('second', current_timestamp - backend_start ),'HH24:MI:SS') AS "Q Conn",
    to_char(xact_start ,'DD HH24:MI:SS')    || ' / ' || to_char(date_trunc('second', current_timestamp - xact_start    ),'HH24:MI:SS') AS "Q Xact",
    to_char(query_start,'DD HH24:MI:SS')    || ' / ' || to_char(date_trunc('second', current_timestamp - query_start   ),'HH24:MI:SS') AS "Q Start",
    to_char(state_change,'DD HH24:MI:SS')   || ' / ' || to_char(date_trunc('second', current_timestamp - state_change  ),'HH24:MI:SS') AS "Q State",
    coalesce(wait_event_type, ' ') || ' / ' || coalesce(wait_event, ' ') || ' / ' || array_to_string(pg_blocking_pids(pid),',')        AS "W Tp/Ev/PID",
    query_id,
    array_to_string(regexp_split_to_array(substr(query,1,50000),'\s+'),' ') || CASE WHEN length(query) > 50000 THEN '...' ELSE '' END    AS "Query"
FROM pg_stat_activity
WHERE
    state != 'idle' AND
    pid != pg_backend_pid() 
    --backend_type = 'client backend'
ORDER BY xact_start, query_start, state_change;
