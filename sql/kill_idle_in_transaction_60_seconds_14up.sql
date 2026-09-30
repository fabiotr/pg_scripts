SELECT
    pid,
    usename AS "User",
    application_name AS "App",
    client_addr AS "Client",
    CURRENT_TIMESTAMP - query_start AS active_time,
    query_id,
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ') || CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query,
    pg_terminate_backend(pid) "Killed?"
FROM pg_stat_activity
WHERE
    state = 'idle in transaction' AND
    backend_type = 'client backend' AND
    query_start < CURRENT_TIMESTAMP - INTERVAL '1 MINUTE';
