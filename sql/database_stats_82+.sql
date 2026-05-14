SELECT
    d.datname AS "Database",
    pg_size_pretty(pg_database_size(d.datname)) AS "Size",
    to_char(100 * xact_rollback::NUMERIC / (xact_rollback + xact_commit),'FM000D99') || ' %' AS "Rollback"
FROM pg_stat_database d
WHERE d.datname = current_database();
