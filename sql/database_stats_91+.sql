SELECT
    d.datname AS "Database",
    pg_size_pretty(pg_database_size(d.datname))                                                                               AS "Size",
    to_char(100 * xact_rollback::NUMERIC / (xact_rollback + xact_commit),'FM000D99') || ' %'                            AS "Rollback",
    to_char(100 * tup_fetched::NUMERIC   / tup_returned                                            ,'FM000D99') || ' %' AS "Rows fetch/return",
    to_char(100 * tup_fetched::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM000D99') || ' %' AS "Rows SELECT",
    to_char(100 * tup_inserted::NUMERIC  / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM000D99') || ' %' AS "Rows INSERT",
    to_char(100 * tup_updated::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM000D99') || ' %' AS "Rows UPDATE",
    to_char(100 * tup_deleted::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM000D99') || ' %' AS "Rows DELETE",
    '------------'                                        AS "Reset",
    to_char(stats_reset, 'YYYY-MM-DD HH24:MI:SS')         AS "Date",
    date_trunc('second', current_timestamp - stats_reset) AS "Age"
FROM pg_stat_database d
WHERE d.datname = current_database();
