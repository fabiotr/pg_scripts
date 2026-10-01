SELECT
    d.datname AS "Database",
    lpad(pg_size_pretty(pg_database_size(d.datname)), 11) AS "Size",
    lpad(to_char(100 * xact_rollback::NUMERIC / (xact_rollback + xact_commit),'FM000D99'), 7) || ' %' AS "Rollback"
FROM pg_stat_database d
WHERE d.datname = current_database();
