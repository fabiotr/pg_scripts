-- AUTOVACUUM ANALYZE adjust goals:
--  50K tuples local mechanical disk
-- 100K tuples storage mechanical disk
-- 250K tuples SSD 
-- 500K tuples SSD write intensive 
\set QUIET on
\timing off
SET lc_numeric = 'C';
SELECT
    'ALTER TABLE ' 
        || n.nspname || '.' || c.relname 
        || ' SET(autovacuum_analyze_scale_factor = ' 
        || CASE 
                WHEN c.scale < '0.0001' THEN to_char(round(c.scale,5),'0D99999')
                WHEN c.scale < '0.001'  THEN to_char(round(c.scale,4),'0D9999')
                WHEN c.scale < '0.01'   THEN to_char(round(c.scale,3),'0D999')
                WHEN c.scale < '0.1'    THEN to_char(round(c.scale,2),'0D99')
                ELSE                         to_char(round(c.scale,1),'0D99999')
           END 
        || '); --' AS "Command", 
    coalesce(t.scale,s.scale) AS current,
    round(c.scale,6) AS new,
    to_char(reltuples, '999G999G999G990')  AS n_live_tup
FROM 
    (SELECT 
            (250000 / reltuples)::NUMERIC scale, -- 250K tuples goal
            relname, relnamespace, relkind, reltuples, oid 
        FROM pg_class) c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN (
        SELECT to_number(trim('autovacuum_analyze_scale_factor=' FROM reloptions),'99.99999') scale, oid
            FROM (
                SELECT unnest(reloptions) reloptions, oid 
                    FROM pg_class 
                    WHERE reloptions IS NOT NULL) i
            WHERE reloptions LIKE 'autovacuum_analyze_scale_factor=%') AS t ON t.oid = c.oid,
    (SELECT to_number(current_setting('autovacuum_analyze_scale_factor'),'99.999') AS scale) AS s
WHERE
    c.relkind IN ('r', 'm', 'p') AND  -- Only tables
    c.reltuples > 1000000        AND  -- Only tables > 1M tuples
    c.scale     < s.scale        AND  -- Only adjust WHERE new value < default value
    coalesce(t.scale,s.scale) !=      -- Only adjust WHERE new value != current value
        CASE 
            WHEN c.scale < '0.0001' THEN round(c.scale,5)
            WHEN c.scale < '0.001'  THEN round(c.scale,4)
            WHEN c.scale < '0.01'   THEN round(c.scale,3)
            WHEN c.scale < '0.1'    THEN round(c.scale,2)
            ELSE                     round(c.scale,1)
        END
ORDER BY c.reltuples DESC
;
RESET lc_numeric;
\timing on
\set QUIET off
