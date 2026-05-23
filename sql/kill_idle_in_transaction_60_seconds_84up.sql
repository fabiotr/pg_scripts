SELECT
    procpid AS "PID",
    usename AS "User",
    client_addr AS "Client",
    current_timestamp - query_start AS active_time,
    array_to_string(regexp_split_to_array(substr(current_query,1,50),'\s+'),' ') || CASE WHEN length(current_query) > 50 THEN '...' ELSE '' END AS query,
    pg_terminate_backend(procpid) "Killed?"
FROM pg_stat_activity
WHERE
    current_query = '<IDLE> in transaction' AND
    query_start < current_timestamp - INTERVAL '1 MINUTE';
