SELECT
    schemaname AS "Schema",
    relname AS "Table",      
    --to_char(n_tup_upd,'999G999G999G999') AS "UPDATEs", 
    to_char(n_tup_upd::NUMERIC * 60 * 60 * 24 / (EXTRACT (EPOCH FROM current_timestamp - stats_reset))::BIGINT,'999G999G990') AS "UPDs / day",
    to_char((n_tup_upd::NUMERIC / tup_updated::NUMERIC) * 100,'990D999') AS "DB UPD %",
    --to_char(n_tup_hot_upd, '999G999G999G999') AS "HOT UPD",
    to_char(n_tup_hot_upd::numeric *100 / n_tup_upd,'990D9') AS "HOT UPD %",
    coalesce (fillfactor::integer, 100) AS "Fillfactor"
FROM 
    pg_stat_user_tables t
    JOIN pg_stat_database ON datname = current_database()
    LEFT JOIN (SELECT oid, option_value AS fillfactor FROM pg_class, pg_options_to_table(reloptions) WHERE option_name = 'fillfactor') f ON f.oid = t.relid
WHERE
    (n_tup_upd::NUMERIC / tup_updated::NUMERIC) > 0.0001 AND
    n_tup_upd > 1000 AND
    n_tup_hot_upd * 100  / n_tup_upd < 95
ORDER BY n_tup_hot_upd / n_tup_upd, n_tup_upd DESC, relname, schemaname
LIMIT 40;
