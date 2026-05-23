SELECT
    t.schemaname AS "Schema",
    t.relname    AS "Table",
    lpad(to_char((t.n_tup_upd + t.n_tup_del)/(EXTRACT(EPOCH FROM current_timestamp - d.stats_reset)::numeric/(60*60*24)), 'FM999G999G999G999'),11) AS "Upd+Del/Day",
    lpad(to_char(t.n_live_tup, 'FM999G999G999G999'),11) AS "Live",
    lpad(pg_size_pretty(pg_table_size(t.relid)),7)      AS "Size",
    lpad(to_char(t.n_dead_tup, 'FM999G999G999G999'),11) AS "Dead",
    CASE t.n_live_tup WHEN 0 THEN '0 bytes' ELSE lpad(pg_size_pretty(((pg_table_size(t.relid)::NUMERIC*t.n_dead_tup::NUMERIC)/(t.n_live_tup+t.n_dead_tup))::bigint),7) END AS "Dead Size",
    CASE t.n_live_tup WHEN 0 THEN 0 ELSE trunc(t.n_dead_tup*100::NUMERIC/(t.n_live_tup+t.n_dead_tup)::NUMERIC,3) END AS "D%",
    trunc(to_number(coalesce(c.scale,s.setting),'99.999') * 100,3) AS "S%",
    --CASE WHEN t.last_autovacuum IS NULL THEN 'never AUTO' ELSE to_char(t.last_autovacuum, 'YY-MM-DD HH24:MI:SS') END last_a,
    --CASE WHEN t.last_vacuum IS NULL THEN 'never MANUAL' ELSE to_char(t.last_vacuum, 'YY-MM-DD HH24:MI:SS') END last_m,
    to_char(now() - greatest(t.last_autovacuum, t.last_vacuum), 'DD HH24:MI:SS')
        || CASE WHEN coalesce(t.last_autovacuum, '-infinity') > coalesce(t.last_vacuum, '-infinity') THEN ' A' ELSE ' M' END AS "Last",
    t.autovacuum_count "Qt A",
    CASE t.autovacuum_count when 0 THEN NULL ELSE to_char((now() - d.stats_reset) / t.autovacuum_count,'DD HH24:MI:SS') END  AS "Avg time",
    CASE WHEN NOT e.enabled THEN 'X' END AS "disabled"
FROM
    pg_stat_all_tables t
    LEFT JOIN (SELECT trim('autovacuum_vacuum_scale_factor=' FROM reloptions) scale, oid
        FROM (SELECT unnest(reloptions) reloptions, oid FROM pg_class WHERE reloptions IS NOT NULL) i
        WHERE reloptions LIKE 'autovacuum_vacuum_scale_factor=%') c ON t.relid = c.oid
    LEFT JOIN (SELECT FALSE enabled, oid
        FROM (SELECT unnest(reloptions) reloptions, oid FROM pg_class WHERE reloptions IS NOT NULL) i
        WHERE reloptions LIKE 'autovacuum_enabled=false') e ON t.relid = e.oid
    JOIN pg_stat_database d ON d.datname = current_database()
    JOIN pg_settings s ON s.name = 'autovacuum_vacuum_scale_factor'
WHERE
    n_live_tup > 0 AND
    n_tup_del + n_tup_upd > 1000 AND
    n_dead_tup >  1000
    OR e.enabled = FALSE
ORDER BY e.enabled, CASE n_live_tup WHEN 0 then 0 ELSE (pg_table_size(t.relid)::NUMERIC*t.n_dead_tup::NUMERIC)/(t.n_live_tup+t.n_dead_tup)::NUMERIC END DESC
LIMIT 20;
