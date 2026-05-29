SELECT
    lpad(d.datname,11)                                                                                                           AS "Database",
    lpad(pg_size_pretty(pg_database_size(d.datname)),11)                                                                         AS "Size",
    lpad(pg_size_pretty(round((current_setting('block_size')::bigint * blks_hit)  / reset_days)::bigint),11)                     AS "Hit/Day",
    lpad(pg_size_pretty(round((current_setting('block_size')::bigint * blks_read) / reset_days)::bigint),11)                     AS "Read/Day",
    lpad(to_char(100 * xact_rollback::NUMERIC / (xact_rollback + xact_commit),'FM000D00') || ' %',11)                            AS "Rollback",
    lpad(to_char(100 * blks_hit::NUMERIC      / (blks_hit + blks_read)       ,'FM900D00') || ' %',11)                            AS "Cache hit",
    lpad(to_char(100 * tup_fetched::NUMERIC   / tup_returned                                            ,'FM990D00') || ' %',11) AS "Rows fetch/return",
    lpad(to_char(100 * tup_fetched::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM990D00') || ' %',11) AS "Rows SELECT",
    lpad(to_char(100 * tup_inserted::NUMERIC  / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM990D00') || ' %',11) AS "Rows INSERT",
    lpad(to_char(100 * tup_updated::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM990D00') || ' %',11) AS "Rows UPDATE",
    lpad(to_char(100 * tup_deleted::NUMERIC   / (tup_fetched + tup_inserted + tup_updated + tup_deleted),'FM990D00') || ' %',11) AS "Rows DELETE",
    CASE deadlocks  WHEN 0 THEN NULL ELSE lpad(to_char(deadlocks::NUMERIC  / reset_days,'FM9G999G990D9'),11) END                 AS "Deadlocks  / Day",
    CASE temp_files WHEN 0 THEN NULL ELSE lpad(to_char(temp_files::NUMERIC / reset_days,'FM9G999G990D0'),11) END                 AS "Temp file  / Day",
    CASE temp_files WHEN 0 THEN NULL ELSE lpad(pg_size_pretty(round(temp_bytes / reset_days)::bigint),11) END                    AS "Temp bytes / Day",
    lpad(date_trunc('second', blk_read_time   / reset_days * INTERVAL '1 MIlLISECOND')::text,11)                                 AS "Read time  / Day",
    lpad(date_trunc('second', blk_write_time  / reset_days * INTERVAL '1 MIlLISECOND')::text,11)                                 AS "Write time / Day",
    '--------------------'                                                                                                       AS "Reset",
    lpad(to_char(stats_reset, 'YYYY-MM-DD HH24:MI:SS')::text,20)                                                                 AS "Date",
    lpad(date_trunc('second', current_timestamp - stats_reset)::text,20)                                                         AS "Age"
FROM (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24) AS reset_days, * FROM pg_stat_database) AS d
WHERE d.datname = current_database();
