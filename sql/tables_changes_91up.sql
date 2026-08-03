SELECT
    schemaname AS "Schema",
    relname AS "Table",
    lpad(to_char(n_live_tup,            'FM999G999G999G999'),15) AS "Rows",
    lpad(to_char(n_tup_ins / reset_days,'FM999G999G999G999'),15) || lpad(' (' || round(100 * n_tup_ins / nullif(sum(n_tup_ins) OVER (),0),1) || ' %)',9) AS "INSERT Rows/Day",
    lpad(to_char(n_tup_del / reset_days,'FM999G999G999G999'),15) || lpad(' (' || round(100 * n_tup_del / nullif(sum(n_tup_del) OVER (),0),1) || ' %)',9) AS "DELETE Rows/Day",
    lpad(to_char(n_tup_upd / reset_days,'FM999G999G999G999'),15) || lpad(' (' || round(100 * n_tup_upd / nullif(sum(n_tup_upd) OVER (),0),1) || ' %)',9) AS "UPDATE Rows/Day",
    lpad(to_char((coalesce(n_tup_ins,0) - coalesce(n_tup_del,0)) / reset_days,'FM999G999G999G999'),15)
        || lpad(' (' || round(100 * (coalesce(n_tup_ins,0) - coalesce(n_tup_del,0)) / 
        nullif(sum(coalesce(n_tup_ins,0) - coalesce(n_tup_del,0)) OVER (),0),1) || ' %)',9)                                                              AS "New rows/Day",
    lpad(to_char((coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) / reset_days,'FM999G999G999G999'),15)
        || lpad(' (' || round(100 * (coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) / 
        nullif(sum(coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) OVER (),0),1) || ' %)',9)                                      AS "DML Rows/Day",
    lpad(to_char((coalesce(seq_tup_read,0) + coalesce(idx_tup_fetch,0)) / reset_days,'FM999G999G999G999'),15) 
        || lpad(' (' || round(100 * (coalesce(seq_tup_read,0) + coalesce(idx_tup_fetch,0)) / 
        nullif(sum(coalesce(seq_tup_read,0) + coalesce(idx_tup_fetch,0)) OVER (),0),1) || ' %)',9)                                                       AS "SELECT Rows/Day",
    lpad(round(100 * (coalesce(seq_tup_read,0) + coalesce(idx_tup_fetch,0)) /
        nullif(coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0) + coalesce(seq_tup_read,0) + coalesce(idx_tup_fetch,0),0),1)
        || ' %',7)                                                                                                                                       AS "SELECT / DML Rows %"
FROM
    pg_stat_all_tables,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days
        FROM pg_stat_database
        WHERE datname = current_database()) AS r
WHERE 
    schemaname != 'pg_toast' AND
    coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0) > 0
ORDER BY coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0) DESC
LIMIT 20;
