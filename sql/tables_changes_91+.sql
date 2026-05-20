SELECT
    schemaname AS "Schema",
    relname AS "Table",
    lpad(to_char(n_live_tup,            'FM999G999G999G999'),15) AS "Rows",
    lpad(to_char(n_tup_ins / reset_days,'FM999G999G999G999'),15) || lpad(' (' || round(100 * n_tup_ins / reset_days/ n_live_tup) || ' %)',8) AS "INSERT Rows/Day",
    lpad(to_char(n_tup_del / reset_days,'FM999G999G999G999'),15) || lpad(' (' || round(100 * n_tup_del / reset_days/ n_live_tup) || ' %)',8) AS "DELETE Rows/Day",
    lpad(to_char(n_tup_upd / reset_days,'FM999G999G999G999'),15) || lpad(' (' || round(100 * n_tup_upd / reset_days/ n_live_tup) || ' %)',8) AS "UPDATE Rows/Day",
    lpad(to_char((coalesce(n_tup_ins,0) - coalesce(n_tup_del,0)) / reset_days,'FM999G999G999G999'),15) 
        || lpad(' (' || round(100 * (coalesce(n_tup_ins,0) - coalesce(n_tup_del,0))/ reset_days/ n_live_tup) || ' %)',8) AS "New rows/Day",
    lpad(to_char((coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) / reset_days,'FM999G999G999G999'),15)
        || lpad(' (' || round(100 * (coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0))/ reset_days/ n_live_tup) || ' %)',8) AS "Change Rows/Day"
FROM
    pg_stat_user_tables,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days
        FROM pg_stat_database
        WHERE datname = current_database()) AS r
ORDER BY coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0) DESC
LIMIT 20;
