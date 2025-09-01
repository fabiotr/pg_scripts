SELECT
    pid, 
    leader_pid,
    array_to_string(pg_blocking_pids(pid),',') AS bl_pid,
    state,
    wait_event_type,
    wait_event,
    datname AS db,
    host(client_addr) AS host,
    usename AS "user", 
    substr(application_name,1, 15) || CASE WHEN length(application_name) > 15 THEN '...' ELSE ' ' END AS app,
    to_char(current_timestamp - backend_start ,'HH24:MI:SS') AS "Q Conn",
    to_char(current_timestamp - xact_start    ,'HH24:MI:SS') AS "Q Xact",
    to_char(current_timestamp - query_start   ,'HH24:MI:SS') AS "Q Start",
    to_char(current_timestamp - state_change  ,'HH24:MI:SS') AS "Q State",
    regexp_match(query, '[space\_id\"|"space"\."id"] \= ([0-9]+)') AS space_id,
    query_id,
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') || CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM pg_stat_activity
WHERE
        state != 'idle' 
    AND pid != pg_backend_pid() 
    --AND backend_type = 'client backend'
ORDER BY xact_start, query_start, state_change;

