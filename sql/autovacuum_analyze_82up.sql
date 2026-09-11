SELECT
    t.schemaname AS "Schema",
    t.relname    AS "Table",
    --lpad(to_char(seq_scan,'FM999G999G999'),11) AS "Seq Scan",
    --lpad(to_char(idx_scan,'FM999G999G999G999'),15) AS "Idx Scan",
    --CASE WHEN coalesce(idx_scan,0) +coalesce(seq_scan,0) = 0 THEN NULL ELSE idx_scan*100 / (idx_scan + seq_scan) END AS "Idx %",
    lpad(to_char(t.n_live_tup, 'FM999G999G999G999'),11)          AS "Live Rows",
    lpad(pg_size_pretty(pg_relation_size(t.relid)),7)            AS "Size",
    lpad(to_char(t.n_mod_since_analyze, 'FM999G999G999G999'),11) AS "Mod",
    CASE t.n_live_tup WHEN 0 THEN 0 ELSE round(t.n_mod_since_analyze*100::NUMERIC/(t.n_live_tup)::NUMERIC,3) END AS "M%",
    round(to_number(coalesce(c.scale,s.setting),'99.99999') * 100,3) AS "S%",
    to_char(now() - greatest(t.last_autoanalyze, t.last_analyze), 'DD HH24:MI:SS')
        || CASE WHEN coalesce(t.last_autoanalyze, '-infinity') > coalesce(t.last_analyze, '-infinity') THEN ' A' ELSE ' M' END AS "Last",
    t.autoanalyze_count AS "Qt A",
    CASE t.autoanalyze_count WHEN 0 THEN NULL ELSE to_char((now() - d.stats_reset) / t.autoanalyze_count,'DD HH24:MI:SS') END AS "Avg time",
    CASE WHEN NOT e.enabled THEN 'X' END AS "Disabled"
FROM
    pg_stat_user_tables t
    LEFT JOIN LATERAL (SELECT option_value AS scale FROM pg_options_to_table((SELECT reloptions FROM pg_class WHERE oid = t.relid)) WHERE option_name = 'autovacuum_analyze_scale_factor') c ON true
    LEFT JOIN LATERAL (SELECT FALSE AS enabled FROM pg_options_to_table((SELECT reloptions FROM pg_class WHERE oid = t.relid)) WHERE option_name = 'autovacuum_enabled' AND option_value = 'false') e ON true
    JOIN pg_stat_database d ON d.datname = current_database()
    JOIN pg_settings s ON s.name = 'autovacuum_analyze_scale_factor'
WHERE
    n_live_tup > 1000 AND
    n_tup_del + n_tup_upd + n_tup_ins> 1000 AND
    n_mod_since_analyze > 1000 OR
    e.enabled = FALSE
ORDER BY e.enabled, CASE n_live_tup WHEN 0 then 0 ELSE t.n_mod_since_analyze/t.n_live_tup END DESC
LIMIT 10;
