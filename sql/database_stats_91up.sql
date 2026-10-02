SELECT
    d.datname AS "Database",
    lpad(pg_size_pretty(pg_database_size(d.datname)), 11)                                                                               AS "Size",
    lpad(to_char(100 * xact_rollback::NUMERIC / (xact_rollback + xact_commit),'FM000D09'), 7) || ' %'                            AS "Rollback",
    lpad(to_char(100 * tup_fetched::NUMERIC   / tup_returned                                            ,'FM000D09'), 7) || ' %' AS "Rows fetch/return",
    lpad(to_char(100 * tup_fetched::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM000D09'), 7) || ' %' AS "Rows SELECT",
    lpad(to_char(100 * tup_inserted::NUMERIC  / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM000D09'), 7) || ' %' AS "Rows INSERT",
    lpad(to_char(100 * tup_updated::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM000D09'), 7) || ' %' AS "Rows UPDATE",
    lpad(to_char(100 * tup_deleted::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM000D09'), 7) || ' %' AS "Rows DELETE",
    '------------'                                        AS "Reset",
    to_char(stats_reset, 'YYYY-MM-DD HH24:MI:SS')         AS "Date",
    date_trunc('second', CURRENT_TIMESTAMP - stats_reset) AS "Age"
FROM pg_stat_database d
WHERE d.datname = current_database();
