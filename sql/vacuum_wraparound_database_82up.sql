SELECT
    datname AS "Database",
    lpad(pg_size_pretty(pg_database_size(datname)), 11) AS "Size",
    round(100*(age(datfrozenxid)/current_setting('autovacuum_freeze_max_age')::float)) AS "% Max Age"
FROM pg_database
ORDER BY age(datfrozenxid) DESC;
