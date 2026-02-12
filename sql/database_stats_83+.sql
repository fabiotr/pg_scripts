SELECT
    d.datname AS "Database",
    pg_size_pretty(pg_database_size(d.datname)) AS "Size",
    trim(to_char(100 * xact_rollback::NUMERIC / (xact_rollback + xact_commit),'000D99') || ' %') AS "Rollback",
    trim(to_char(100 * tup_fetched::NUMERIC   / tup_returned                                             ,'000D99') || ' %') AS "Rows feth/retun",
    trim(to_char(100* tup_returned::NUMERIC   / (tup_returned + tup_inserted + tup_updated + tup_deleted),'000D99') || ' %') AS "Rows SELECT",
    trim(to_char(100* tup_inserted::NUMERIC   / (tup_returned + tup_inserted + tup_updated + tup_deleted),'000D99') || ' %') AS "Rows INSERT",
    trim(to_char(100* tup_updated::NUMERIC    / (tup_returned + tup_inserted + tup_updated + tup_deleted),'000D99') || ' %') AS "Rows UPDATE",
    trim(to_char(100* tup_deleted::NUMERIC    / (tup_returned + tup_inserted + tup_updated + tup_deleted),'000D99') || ' %') AS "Rows DELETE"
FROM pg_stat_database d
WHERE d.datname = current_database();
