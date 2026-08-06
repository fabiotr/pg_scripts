-- AUTOVACUUM VACUUM adjust goals:
--  10 MB local mechanical disk
--  20 MB storage mechanical disk
--  50 MB SSD 
-- 100 MB SSD write intensive
SET lc_numeric = 'C';
SELECT
    CASE WHEN c.scale < s.scale THEN
        'ALTER TABLE '
            || quote_ident(n.nspname) || '.' || quote_ident(c.relname)
            || ' SET (autovacuum_vacuum_scale_factor = '
            || CASE
                    WHEN c.scale < '0.0001' THEN to_char(round(c.scale,5),'FM0D99999')
                    WHEN c.scale < '0.001'  THEN to_char(round(c.scale,4),'FM0D9999')
                    WHEN c.scale < '0.01'   THEN to_char(round(c.scale,3),'FM0D999')
                    WHEN c.scale < '0.1'    THEN to_char(round(c.scale,2),'FM0D99')
                    ELSE                         to_char(round(c.scale,1),'FM0D9')
            END
            || '); --' 
        ELSE '-- ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname)
    END || chr(10) ||
    CASE WHEN ct.scale < s.scale THEN
        'ALTER TABLE '
            || quote_ident(n.nspname) || '.' || quote_ident(c.relname)
            || ' SET (toast.autovacuum_vacuum_scale_factor = '
            || CASE
                    WHEN ct.scale < '0.0001' THEN to_char(round(ct.scale,5),'FM0D99999')
                    WHEN ct.scale < '0.001'  THEN to_char(round(ct.scale,4),'FM0D9999')
                    WHEN ct.scale < '0.01'   THEN to_char(round(ct.scale,3),'FM0D999')
                    WHEN ct.scale < '0.1'    THEN to_char(round(ct.scale,2),'FM0D99')
                    ELSE                          to_char(round(ct.scale,1),'FM0D9')
            END
            || '); --'
        ELSE '-- ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) || ' TOAST'
    END AS "Command",
    coalesce(to_number(cs.option_value, '99.99999'),s.scale) || chr(10) ||
    coalesce(to_number(cts.option_value, '99.99999'),s.scale) AS current,
    lpad(pg_size_pretty(pg_relation_size(c.oid,'main')),7) || chr(10) ||  
    lpad(pg_size_pretty(pg_relation_size(ct.oid)),7)  AS size
FROM
    (
        SELECT
            (100*1024*1024) / nullif(pg_relation_size(oid,'main'),0)::NUMERIC scale, -- 100*1024*1024 = 100MB goal
            relname, relnamespace, relkind, relpages, reltoastrelid, reloptions, oid
        FROM pg_class) c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN (
        SELECT 
            (100*1024*1024) / nullif(pg_relation_size(oid),0)::NUMERIC scale, -- 100*1024*1024 = 100MB goal
            relname, relnamespace, relkind, relpages, reloptions, oid
        FROM pg_class) ct ON c.reltoastrelid = ct.oid
    LEFT JOIN pg_options_to_table(c.reloptions)  AS cs ON cs.option_name = 'autovacuum_vacuum_scale_factor'
    LEFT JOIN pg_options_to_table(ct.reloptions) AS cts ON cts.option_name = 'autovacuum_vacuum_scale_factor',
    (SELECT to_number(current_setting('autovacuum_vacuum_scale_factor'),'99.99999') AS scale) AS s
WHERE
    c.relkind IN ('r', 'm', 'p') AND  -- Only tables
    c.relpages > 0               AND  -- Avoid division by zero
    (c.scale  < s.scale AND  -- Only adjust WHERE new value < default valuE
        coalesce(to_number(cs.option_value, '99.99999'),s.scale) !=  -- Only adjust WHERE new value != current value
                CASE
                    WHEN c.scale < '0.0001' THEN round(c.scale,5)
                    WHEN c.scale < '0.001'  THEN round(c.scale,4)
                    WHEN c.scale < '0.01'   THEN round(c.scale,3)
                    WHEN c.scale < '0.1'    THEN round(c.scale,2)
                    ELSE                         round(c.scale,1)
                END) 
    OR 
     (ct.scale < s.scale AND  -- Only adjust WHERE new value < default valuE
        coalesce(to_number(cts.option_value,'99.99999'),s.scale) !=  -- Only adjust WHERE new value != current value
            CASE
                WHEN ct.scale < '0.0001' THEN round(ct.scale,5)
                WHEN ct.scale < '0.001'  THEN round(ct.scale,4)
                WHEN ct.scale < '0.01'   THEN round(ct.scale,3)
                WHEN ct.scale < '0.1'    THEN round(ct.scale,2)
                ELSE                          round(ct.scale,1)
            END)
ORDER BY greatest(pg_relation_size(c.oid,'main'), pg_relation_size(ct.oid)) DESC
;
RESET lc_numeric ;
