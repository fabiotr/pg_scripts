SELECT
    t.schemaname "Schema", 
    t.relname "Table", 
    to_char((t.n_tup_upd + t.n_tup_del)/(EXTRACT(EPOCH FROM current_timestamp - d.stats_reset)::numeric/(60*60*24)), '999G999G999G999') "Upd+Del/Day",
    to_char(t.n_live_tup, '99G999G999G999')  "Live Rows", 
    to_char(tt.n_live_tup, '99G999G999G999') "Live T Rows",
    to_char(t.n_dead_tup, '99G999G999G999')  "Dead Rows",
    to_char(tt.n_dead_tup, '99G999G999G999') "Dead T Rows",
    pg_size_pretty(pg_relation_size(t.relid, 'main')) "Size",
    pg_size_pretty(pg_relation_size(tt.relid)) "Size T",
    pg_size_pretty(pg_indexes_size(t.relid)) "Size Ind",
    --pg_size_pretty(pg_table_size(t.relid) + pg_indexes_size(t.relid)) "Size Total",
    CASE t.n_live_tup WHEN 0 THEN '0 bytes' ELSE pg_size_pretty((pg_relation_size(t.relid, 'main')::NUMERIC*t.n_dead_tup::NUMERIC)/(t.n_live_tup+t.n_dead_tup)::NUMERIC) END "Dead Size",
    CASE tt.n_live_tup WHEN 0 THEN '0 bytes' ELSE pg_size_pretty(trunc((pg_relation_size(tt.relid, 'main')::NUMERIC*tt.n_dead_tup::NUMERIC)/(tt.n_live_tup+tt.n_dead_tup)::NUMERIC)) END "Dead T Size",
    CASE t.n_live_tup WHEN 0 THEN 0 ELSE trunc(t.n_dead_tup*100::NUMERIC/(t.n_live_tup+t.n_dead_tup)::NUMERIC,3) END "D%", 
    CASE tt.n_live_tup WHEN 0 THEN 0 ELSE trunc(tt.n_dead_tup*100::NUMERIC/(tt.n_live_tup+tt.n_dead_tup)::NUMERIC,3) END "D T%", 
    trunc(to_number(coalesce(sc.scale,s.setting), '99.99999') * 100 ,3) "S%",
    trunc(to_number(coalesce(sct.scale,sc.scale,s.setting),'99.99999') * 100,3) "S T%",
    to_char(now() - greatest(t.last_autovacuum, t.last_vacuum), 'DD HH24:MI:SS') 
        || CASE WHEN coalesce(t.last_autovacuum, '-infinity') > coalesce(t.last_vacuum, '-infinity') THEN ' A' ELSE ' M' END "Last",
    t.autovacuum_count "Qt A",
    CASE t.autovacuum_count when 0 THEN NULL ELSE to_char((now() - d.stats_reset) / t.autovacuum_count,'DD HH24:MI:SS') END "Avg time",
    CASE WHEN NOT e.enabled THEN 'X' END "disabled"
FROM 
    pg_stat_all_tables t
    JOIN pg_class c ON t.relid = c.oid
    LEFT JOIN pg_class ct ON c.reltoastrelid = ct.oid
    LEFT JOIN pg_stat_all_tables tt ON tt.relid = ct.oid
    LEFT JOIN (SELECT trim('autovacuum_vacuum_scale_factor=' FROM reloptions) scale, oid
        FROM (SELECT unnest(reloptions) reloptions, oid FROM pg_class WHERE reloptions IS NOT NULL) i
        WHERE reloptions LIKE 'autovacuum_vacuum_scale_factor=%') sc ON t.relid = sc.oid
    LEFT JOIN (SELECT trim('autovacuum_vacuum_scale_factor=' FROM reloptions) scale, oid
        FROM (SELECT unnest(reloptions) reloptions, oid FROM pg_class WHERE reloptions IS NOT NULL) i
        WHERE reloptions LIKE 'autovacuum_vacuum_scale_factor=%') sct ON tt.relid = sct.oid
    LEFT JOIN (SELECT FALSE enabled, oid
        FROM (SELECT unnest(reloptions) reloptions, oid FROM pg_class WHERE reloptions IS NOT NULL) i
        WHERE reloptions LIKE 'autovacuum_enabled=false') e ON t.relid = e.oid
    JOIN pg_stat_database d ON d.datname = current_database()
    JOIN pg_settings s ON s.name = 'autovacuum_vacuum_scale_factor'
WHERE
    c.relname NOT LIKE 'pg_toast_%' AND
    t.n_live_tup > 0 AND
    t.n_tup_del + t.n_tup_upd > 1000 AND
    t.n_dead_tup >  1000 
    OR e.enabled = FALSE
ORDER BY e.enabled, CASE t.n_live_tup WHEN 0 then 0 ELSE (pg_table_size(t.relid)::NUMERIC*t.n_dead_tup::NUMERIC)/(t.n_live_tup+t.n_dead_tup)::NUMERIC END DESC
LIMIT 40;

