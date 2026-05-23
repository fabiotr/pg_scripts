SELECT
    datname AS "Database",
    pg_size_pretty(pg_database_size(datname)) AS "Size",
    round(age(datfrozenxid) * 100.0 / current_setting('autovacuum_freeze_max_age')::numeric, 1) || '%' AS "XID Max",
    round(age(datfrozenxid) * 100.0 / current_setting('vacuum_failsafe_age')::numeric, 1) || '%' AS "XID Failsafe",
    round(age(datfrozenxid) * 100.0 / 2147483648, 1) || '%' AS "XID Total",
    round(mxid_age(datminmxid) * 100.0 / current_setting('autovacuum_multixact_freeze_max_age')::numeric, 1) || '%' AS "MXID Max",
    round(mxid_age(datminmxid) * 100.0 / current_setting('vacuum_failsafe_age')::numeric, 1) || '%' AS "MXID Failsafe",
    round(mxid_age(datminmxid) * 100.0 / 2147483648, 1) || '%' AS "MXID Total",
    CASE
        WHEN age(datfrozenxid) > current_setting('vacuum_failsafe_age')::numeric THEN '🔴 CRITIC'
        WHEN age(datfrozenxid) >  current_setting('vacuum_failsafe_age')::numeric / 2 THEN '🟠 WARNING'
        WHEN age(datfrozenxid) >  current_setting('autovacuum_freeze_max_age')::numeric THEN '🟡 ATENTION'
        ELSE '✅ OK'
    END AS "XID Staus",

    CASE
        WHEN mxid_age(datminmxid) > current_setting('vacuum_failsafe_age')::numeric THEN '🔴 CRITIC'
        WHEN mxid_age(datminmxid) > current_setting('vacuum_failsafe_age')::numeric / 2 THEN '🟠 WARNING'
        WHEN mxid_age(datminmxid) >  current_setting('autovacuum_multixact_freeze_max_age')::numeric THEN '🟡 ATENTION'
        ELSE '✅ OK'
    END AS "MXID status"
FROM pg_database
ORDER BY greatest(age(datfrozenxid), mxid_age(datminmxid)) DESC;
