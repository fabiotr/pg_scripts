SELECT 
    'WAITING' AS i,
    '=======' AS ii,
    waiting.pid                 AS pid, 
    waiting_stm.usename         AS user,
    waiting_stm.client_addr     AS ip,
    to_char(waiting_stm.query_start,'DD HH24:MI:SS') || ' | ' || to_char(date_trunc('second', clock_timestamp() - waiting_stm.query_start),'HH24:MI:SS') AS query_start,
    to_char(waiting_stm.xact_start,'DD HH24:MI:SS')  || ' | ' || to_char(date_trunc('second', now() - waiting_stm.xact_start),'HH24:MI:SS')AS xact_start,
    to_char(waiting_stm.backend_start,'DD HH24:MI:SS')  || ' | ' || to_char(date_trunc('second', now() - waiting_stm.backend_start),'HH24:MI:SS')AS connection_start,
    waiting.locktype            AS locktype, 
    waiting.mode                AS mode,
    waiting.relation::regclass  AS table, 
    waiting.granted             AS granted,
    waiting_stm.current_query   AS query, 
    'LOCKER' AS iii,
    '======' AS iiii,
    other.pid                   AS pid, 
    other_stm.usename           AS user,
    other_stm.client_addr       AS ip,
    to_char(other_stm.query_start,'DD HH24:MI:SS') || ' | ' || to_char(date_trunc('second', now() - other_stm.query_start),'HH24:MI:SS') AS query_start,
    to_char(other_stm.xact_start,'DD HH24:MI:SS')  || ' | ' || to_char(date_trunc('second', now() - other_stm.xact_start),'HH24:MI:SS')  AS xact_start,
    to_char(other_stm.backend_start,'DD HH24:MI:SS')  || ' | ' || to_char(date_trunc('second', now() - other_stm.backend_start),'HH24:MI:SS')  AS connection_start,
    
    other.locktype              AS locktype, 
    other.mode                  AS mode, 
    other.relation::regclass    AS table, 
    other.granted               AS granted,
    other_stm.current_query     AS query 
   FROM pg_locks waiting
   JOIN pg_stat_activity waiting_stm ON waiting_stm.procpid = waiting.pid
   JOIN pg_locks other ON waiting.database = other.database AND waiting.relation = other.relation OR waiting.transactionid = other.transactionid
   JOIN pg_stat_activity other_stm ON other_stm.procpid = other.pid
  WHERE waiting.granted = false AND waiting.pid <> other.pid
  ORDER BY other.granted DESC, other_stm.xact_start, waiting_stm.xact_start;
