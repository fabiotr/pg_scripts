-- AUTOVACUUM VACUUM adjust goals:
--  10 MB local mechanical disk
--  20 MB storage mechanical disk
--  50 MB SSD 
-- 100 MB SSD write intensive 
SET lc_numeric = 'C';
SELECT
    'ALTER TABLE ' 
        || n.nspname || '.' || c.relname 
        || ' SET(autovacuum_vacuum_scale_factor = ' 
        || CASE 
                WHEN c.scale < '0.0001' THEN to_char(round(c.scale,5),'0D99999')
                WHEN c.scale < '0.001'  THEN to_char(round(c.scale,4),'0D9999')
                WHEN c.scale < '0.01'   THEN to_char(round(c.scale,3),'0D999')
                WHEN c.scale < '0.1'    THEN to_char(round(c.scale,2),'0D99')
                ELSE                         to_char(round(c.scale,1),'0D9')
           END 
        || '); --' AS "Command", 
    coalesce(t.scale,s.scale) AS current,
    --round(c.scale,6) AS new,
    pg_size_pretty(pg_table_size(c.oid))  AS size
FROM 
    (SELECT 
            (100*1024*1024) / pg_table_size(oid)::NUMERIC scale, -- 100*1024*1024 = 100MB goal
            relname, relnamespace, relkind, relpages, oid 
        FROM pg_class) c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN (
        SELECT to_number(trim('autovacuum_vacuum_scale_factor=' FROM reloptions),'99.99999') scale, oid
            FROM (
                SELECT unnest(reloptions) reloptions, oid 
                    FROM pg_class 
                    WHERE reloptions IS NOT NULL) i
            WHERE reloptions LIKE 'autovacuum_vacuum_scale_factor=%') AS t ON t.oid = c.oid,
    (SELECT to_number(current_setting('autovacuum_vacuum_scale_factor'),'99.999') AS scale) AS s
WHERE
    c.relkind IN ('r', 'm', 'p') AND  -- Only tables
    c.relpages > 0               AND  -- Avoid division by zero
    c.scale < s.scale            AND  -- Only adjust WHERE new value < default value
    coalesce(t.scale,s.scale) !=      -- Only adjust WHERE new value != current value
        CASE 
            WHEN c.scale < '0.0001' THEN round(c.scale,5)
            WHEN c.scale < '0.001'  THEN round(c.scale,4)
            WHEN c.scale < '0.01'   THEN round(c.scale,3)
            WHEN c.scale < '0.1'    THEN round(c.scale,2)
            ELSE                     round(c.scale,1)
        END
ORDER BY c.relpages DESC
;
RESET lc_numeric ;
