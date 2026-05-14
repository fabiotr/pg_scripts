SELECT
    origin AS "Origin",
    db AS "DB",
    u AS "User",
    id AS "Id",
    status AS "Status",
    to_char(age,'FM999G999G999') AS "Age",
    to_char(current_timestamp - duration,'HH24:MI:SS') AS "Duration",
    to_char(coalesce(txid_current_if_assigned(), txid_current())::text::int8 - txid_snapshot_xmin(txid_current_snapshot())::text::int8,'FM999G999G999') AS "Xids blocking vacuum"
FROM 
    (SELECT 
        'Query'           AS origin, 
        datname           AS db, 
        usename           AS u,
        pid::text         AS id,
	state             AS status,
        greatest(age(backend_xmin), age(backend_xid)) AS age,
        xact_start        AS duration
    FROM pg_stat_activity
    WHERE
        pid != pg_backend_pid() AND
        (backend_xmin IS NOT NULL OR backend_xid IS NOT NULL)
    UNION
    SELECT
        'Prepared Xact',
        database,
        owner,
        gid::text,
        'N/A',
        age(transaction),
        prepared
    FROM pg_prepared_xacts
    WHERE transaction IS NOT NULL
    UNION
    SELECT
        'Replication Slot',
        database,
        'N/A',
        slot_name,
        slot_type || ' ' || CASE WHEN active THEN 'active' ELSE 'inactive' END,
        greatest(age(catalog_xmin),age(xmin)),
        NULL
    FROM pg_replication_slots
    WHERE greatest(age(catalog_xmin),age(xmin)) IS NOT NULL
    UNION
    SELECT
        'Replication',
        'N/A',
        usename,
        client_addr::text,
        state,
        age(backend_xmin),
        reply_time
    FROM pg_stat_replication
    WHERE backend_xmin IS NOT NULL) i
ORDER BY age DESC, duration DESC
LIMIT 20;

