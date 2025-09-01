SELECT
    d.datname AS "Database",
    pg_size_pretty(pg_database_size(d.datname)) AS "Size",
    trim(to_char(100 * xact_rollback::NUMERIC / (xact_rollback + xact_commit),'000D99') || ' %') AS "Rollback"
FROM pg_stat_database d
WHERE d.datname = current_database();
