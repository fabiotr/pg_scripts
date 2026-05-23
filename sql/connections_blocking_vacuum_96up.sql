SELECT
    a.pid,
    a.datname AS "DB",
    a.usename AS "User",
    --a.application_name,
    --a.client_addr,
    a.state AS "Status",
    a.wait_event_type AS "Wait",
    a.wait_event,
    to_char(current_timestamp - xact_start    ,'HH24:MI:SS') AS "Xact T",
    to_char(current_timestamp - query_start   ,'HH24:MI:SS') AS "Query T",
    to_char(age(a.backend_xid), 'FM999G999G999')             AS xid_age,
    to_char(age(a.backend_xmin),'FM999G999G999')             AS xmin_age,
    CASE
        WHEN pg_is_in_recovery() THEN 'N/A'
        ELSE to_char(txid_current()::text::int8 - txid_snapshot_xmin(txid_current_snapshot())::text::int8,'FM999G999G999') 
	END AS "XIDs blk",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ') || CASE WHEN length(query) > 50 THEN '...' ELSE '' END AS query
FROM 
    pg_stat_activity a
WHERE 
    pid != pg_backend_pid()AND 
    (backend_xmin IS NOT NULL OR backend_xid IS NOT NULL)
ORDER BY greatest(age(backend_xmin), age(backend_xid)) DESC, xact_start
LIMIT 10;

