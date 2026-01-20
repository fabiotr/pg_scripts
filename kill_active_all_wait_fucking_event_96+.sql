-- Kill all sessions with an wait_event_type, except for 'Client'
SELECT
    pid,
    usename AS "User",
    application_name AS "App",
    client_addr AS "Client",
    current_timestamp - query_start AS active_time,
    query_id,
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') || CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query,
    pg_terminate_backend(pid) "Killed?"
FROM 
    pg_stat_activity AS a
WHERE 
    state = 'active' AND
    backend_type = 'client backend' AND
    wait_event_type IN ('Activity', 'BufferPin', 'Extension', 'InjectionPoint', 'IO', 'IPC', 'Lock', 'LWLock', 'Timeout')
ORDER BY query_start;
