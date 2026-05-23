SELECT
    procpid, 
    waiting,
    datname AS db,
    host(client_addr) AS host,
    usename AS "user", 
    to_char(current_timestamp - backend_start ,'HH24:MI:SS') AS "Q Conn",
    to_char(current_timestamp - xact_start    ,'HH24:MI:SS') AS "Q Xact",
    to_char(current_timestamp - query_start   ,'HH24:MI:SS') AS "Q Start",
    substr(current_query,1,50) AS query
FROM pg_stat_activity
WHERE
        current_query != '<IDLE>' 
    AND procpid != pg_backend_pid() 
    --AND backend_type = 'client backend'
ORDER BY xact_start, query_start;

