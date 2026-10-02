SELECT
    datname AS "Database",
    lpad(pg_size_pretty(pg_database_size(datname)), 11) AS "Size",
    format('%9s', round(age(datfrozenxid) * 100.0 / current_setting('autovacuum_freeze_max_age')::numeric, 1) || '%') AS "XID Max",
    lpad(round(age(datfrozenxid) * 100.0 / 2147483648, 1) || '%', 6) AS "XID Total",
    format('%9s', round(mxid_age(datminmxid) * 100.0 / current_setting('autovacuum_multixact_freeze_max_age')::numeric, 1) || '%') AS "MXID Max",
    lpad(round(mxid_age(datminmxid) * 100.0 / 2147483648, 1) || '%', 6) AS "MXID Total",
    CASE
        WHEN age(datfrozenxid) > 1600000000 THEN '🔴 CRITIC'
        WHEN age(datfrozenxid) >  800000000 THEN '🟠 WARNING'
        WHEN age(datfrozenxid) >  current_setting('autovacuum_freeze_max_age')::numeric THEN '🟡 ATENTION'
        ELSE '✅ OK'
    END AS "XID Status",
    CASE
        WHEN mxid_age(datminmxid) > 1600000000 THEN '🔴 CRITIC'
        WHEN mxid_age(datminmxid) >  800000000 THEN '🟠 WARNING'
        WHEN mxid_age(datminmxid) >  current_setting('autovacuum_multixact_freeze_max_age')::numeric THEN '🟡 ATENTION'
        ELSE '✅ OK'
    END AS "MXID status"
FROM pg_database
ORDER BY greatest(age(datfrozenxid), mxid_age(datminmxid)) DESC;

