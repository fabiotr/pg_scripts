\x auto
SELECT 
    'WAITING' AS ".",
    '=======' AS ".",
    rpad(waiting.pid::text,11)   || ' - ' || coalesce(waiting_stm.client_addr::text, 'LOCAL') AS "pid  - IP", 
    rpad(waiting_stm.usename,11) || ' - ' || waiting_stm.application_name                     AS "User - App",
    to_char(waiting_stm.backend_start,'DD HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - waiting_stm.backend_start),'HH24:MI:SS') AS "Start conn",
    to_char(waiting_stm.xact_start   ,'DD HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - waiting_stm.xact_start)   ,'HH24:MI:SS') AS "Start xact",
    to_char(waiting_stm.query_start  ,'DD HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - waiting_stm.query_start)  ,'HH24:MI:SS') AS "Start query",
    to_char(waiting_stm.state_change ,'DD HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - waiting_stm.state_change) ,'HH24:MI:SS') AS "State chang",
    rpad(waiting.granted::text,11) || ' - ' || waiting.locktype || '/' || waiting.mode        AS "Grant - Typ",
    waiting.relation::regclass                                                                AS "Table", 
    '<' || waiting_stm.state || '> '                                                          AS "State",
    waiting_stm.query                                                                         AS "Query",
    'LOCKER' AS ".",
    '======' AS ".",
    rpad(other.pid::text,11)   || ' - '  || coalesce(other_stm.client_addr::text, 'LOCAL')    AS "pid  - IP",
    rpad(other_stm.usename,11) || ' - '  || other_stm.application_name                        AS "User - App",
    to_char(other_stm.backend_start,'DD HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - other_stm.backend_start),'HH24:MI:SS') AS "Start conn",
    to_char(other_stm.xact_start   ,'DD HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - other_stm.xact_start)   ,'HH24:MI:SS') AS "Start xact",
    to_char(other_stm.query_start  ,'DD HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - other_stm.query_start)  ,'HH24:MI:SS') AS "Start query",
    to_char(other_stm.state_change ,'DD HH24:MI:SS') || ' - ' || to_char(date_trunc('second', clock_timestamp() - other_stm.state_change) ,'HH24:MI:SS') AS "State chang",
    rpad(other.granted::text,11) || ' - ' || other.locktype || '/' || other.mode              AS "Grant - Typ",
    other.relation::regclass                                                                  AS "Table", 
    '<' || other_stm.state || '> '                                                            AS "State",
    other_stm.query                                                                           AS "Query"
FROM     pg_locks waiting
    JOIN pg_stat_activity waiting_stm ON waiting_stm.pid = waiting.pid
    JOIN pg_locks other ON waiting.database = other.database AND waiting.relation = other.relation OR waiting.transactionid = other.transactionid
    JOIN pg_stat_activity other_stm ON other_stm.pid = other.pid
WHERE waiting.granted = false AND waiting.pid <> other.pid
ORDER BY other.granted DESC, other_stm.xact_start, waiting_stm.xact_start;

