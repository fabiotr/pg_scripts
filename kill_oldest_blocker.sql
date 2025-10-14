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
    JOIN (SELECT unnest(pg_blocking_pids(pid)) AS blocking_pid FROM pg_stat_activity WHERE array_length(pg_blocking_pids(pid),1) > 0) AS b ON b.blocking_pid = a.pid
ORDER BY xact_start
LIMIT 1;
