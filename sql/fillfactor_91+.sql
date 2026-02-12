SELECT
    t.schemaname AS "Schema",
    t.relname AS "Table",
    --to_char(n_tup_upd,'999G999G999G999') AS "UPDATEs",
    to_char(n_tup_upd::NUMERIC * 60 * 60 * 24 / (EXTRACT (EPOCH FROM current_timestamp - stats_reset))::BIGINT,'999G999G990') AS "UPDs / day",
    to_char((n_tup_upd::NUMERIC / tup_updated::NUMERIC) * 100,'990D999') AS "DB UPD %",
    --to_char(n_tup_hot_upd, '999G999G999G999') AS "HOT UPD",
    to_char(n_tup_hot_upd::numeric *100 / n_tup_upd,'990D9') AS "HOT UPD %",
    coalesce ((SELECT option_value::integer FROM pg_options_to_table(c.reloptions) WHERE option_name = 'fillfactor'), 100) AS "Fillfactor"
FROM
    pg_stat_user_tables t
    JOIN pg_stat_database ON datname = current_database()
    LEFT JOIN pg_class c ON c.oid = t.relid
WHERE
    (n_tup_upd::NUMERIC / tup_updated::NUMERIC) > 0.0001 AND
    n_tup_upd > 1000 AND
    n_tup_hot_upd * 100  / n_tup_upd < 95
ORDER BY n_tup_hot_upd / n_tup_upd, n_tup_upd DESC, t.relname, t.schemaname
LIMIT 40;
