SELECT
    procpid, 
    waiting,
    datname AS db,
    host(client_addr) AS host,
    usename AS "user", 
    substr(application_name,1, 15) || CASE WHEN length(application_name) > 15 THEN '...' ELSE ' ' END AS app,
    to_char(current_timestamp - backend_start ,'HH24:MI:SS') AS "Q Conn",
    to_char(current_timestamp - xact_start    ,'HH24:MI:SS') AS "Q Xact",
    to_char(current_timestamp - query_start   ,'HH24:MI:SS') AS "Q Start",
    array_to_string(regexp_split_to_array(substr(current_query,1,50),'\s+'),' ') || CASE WHEN length(current_query) > 50 THEN '...' ELSE '' END AS query
FROM pg_stat_activity
WHERE
        current_query != '<IDLE>' 
    AND procpid != pg_backend_pid() 
    --AND backend_type = 'client backend'
ORDER BY xact_start, query_start;

