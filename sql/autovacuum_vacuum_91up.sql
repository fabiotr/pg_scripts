SELECT
    t.schemaname AS "Schema",
    t.relname    AS "Table",
    lpad(to_char((t.n_tup_upd + t.n_tup_del)/(EXTRACT(epoch FROM CURRENT_TIMESTAMP - COALESCE(d.stats_reset, :svp_stats_start_db))::numeric/(60*60*24)), 'FM999G999G999G999'),16) AS "Upd+Del/Day",
    lpad(to_char(t.n_live_tup, 'FM999G999G999G999'),16) AS "Live",
    lpad(pg_size_pretty(pg_table_size(t.relid)),11)      AS "Size",
    lpad(to_char(t.n_dead_tup, 'FM999G999G999G999'),16) AS "Dead",
    lpad(CASE t.n_live_tup WHEN 0 THEN '0 bytes' ELSE pg_size_pretty(((pg_table_size(t.relid)::NUMERIC*t.n_dead_tup::NUMERIC)/(t.n_live_tup+t.n_dead_tup))::bigint) END, 11) AS "Dead Size",
    CASE t.n_live_tup WHEN 0 THEN 0 ELSE trunc(t.n_dead_tup*100::NUMERIC/(t.n_live_tup+t.n_dead_tup)::NUMERIC,3) END AS "D%",
    trunc(to_number(coalesce(t.scale,s.setting),'99.999') * 100,3) AS "S%",
    --CASE WHEN t.last_autovacuum IS NULL THEN 'never AUTO' ELSE to_char(t.last_autovacuum, 'YY-MM-DD HH24:MI:SS') END last_a,
    --CASE WHEN t.last_vacuum IS NULL THEN 'never MANUAL' ELSE to_char(t.last_vacuum, 'YY-MM-DD HH24:MI:SS') END last_m,
    to_char(now() - greatest(t.last_autovacuum, t.last_vacuum), 'DD HH24:MI:SS')
        || CASE WHEN coalesce(t.last_autovacuum, '-infinity') > coalesce(t.last_vacuum, '-infinity') THEN ' A' ELSE ' M' END AS "Last",
    t.autovacuum_count "Qt A",
    CASE t.autovacuum_count WHEN 0 THEN NULL ELSE to_char((now() - COALESCE(d.stats_reset, :svp_stats_start_db)) / t.autovacuum_count,'DD HH24:MI:SS') END  AS "Avg time",
    CASE WHEN NOT t.enabled THEN 'X' END AS "disabled"
FROM
    (SELECT
        st.*,
        (SELECT option_value FROM pg_options_to_table(rc.reloptions) WHERE option_name = 'autovacuum_vacuum_scale_factor') AS scale,
        (SELECT FALSE FROM pg_options_to_table(rc.reloptions) WHERE option_name = 'autovacuum_enabled' AND option_value = 'false') AS enabled
    FROM pg_stat_all_tables st JOIN pg_class rc ON rc.oid = st.relid) t
    JOIN pg_stat_database d ON d.datname = current_database()
    JOIN pg_settings s ON s.name = 'autovacuum_vacuum_scale_factor'
WHERE
    t.schemaname != 'pg_toast' AND
    n_live_tup > 0 AND
    n_tup_del + n_tup_upd > 1000 AND
    n_dead_tup >  1000
    OR t.enabled = FALSE
ORDER BY t.enabled, CASE n_live_tup WHEN 0 THEN 0 ELSE (pg_table_size(t.relid)::NUMERIC*t.n_dead_tup::NUMERIC)/(t.n_live_tup+t.n_dead_tup)::NUMERIC END DESC
LIMIT 20;
