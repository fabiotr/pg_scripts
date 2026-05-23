SELECT
    schemaname AS "Schema",
    relname AS "Table",
    lpad(to_char(n_live_tup,            'FM999G999G999G999'),15) AS "Rows",
    lpad(to_char((coalesce(seq_tup_read,0) + coalesce(idx_tup_fetch,0)) / reset_days,'FM999G999G999G999'),15) AS "SELECT Rows/Day"
FROM
    pg_stat_all_tables,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days
        FROM pg_stat_database
        WHERE datname = current_database()) AS r
ORDER BY coalesce(seq_tup_read,0) + coalesce(idx_tup_fetch,0) DESC
LIMIT 10;

