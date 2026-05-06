SELECT
    a.pid, 
    a.backend_type,
    a.state,
    a.wait_event_type,
    a.wait_event,
    a.datname AS db,
    a.host(client_addr) AS host,
    a.usename AS "user", 
    sum(i.read_bytes) AS "Read"

    to_char(current_timestamp - backend_start ,'HH24:MI:SS') AS "Q Conn",
    to_char(current_timestamp - query_start   ,'HH24:MI:SS') AS "Q Start",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') || CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM 
    pg_stat_activity AS a,
    LATERAL pg_stat_get_backend_io(pid) AS i
WHERE
        state != 'idle' 
    AND pid != pg_backend_pid() 
GROUP BY a.pid, a.backend_type, a.state, a.wait_event_type, a.wait_event, a.datname, a.client_addr, a.usename, a.backend_start, a.query_start, a.query
ORDER BY xact_start, query_start, state_change;

