-- AUTOVACUUM ANALYZE adjust goals:
--  50K tuples local mechanical disk
-- 100K tuples storage mechanical disk
-- 250K tuples SSD 
-- 500K tuples SSD write intensive 
SET lc_numeric = 'C';
SELECT
    'ALTER TABLE ' 
        || quote_ident(n.nspname) || '.' || quote_ident(c.relname)
        || ' SET(autovacuum_analyze_scale_factor = ' 
        || CASE 
                WHEN c.scale < '0.0001' THEN to_char(round(c.scale,5),'FM0D99999')
                WHEN c.scale < '0.001'  THEN to_char(round(c.scale,4),'FM0D9999')
                WHEN c.scale < '0.01'   THEN to_char(round(c.scale,3),'FM0D999')
                WHEN c.scale < '0.1'    THEN to_char(round(c.scale,2),'FM0D99')
                ELSE                         to_char(round(c.scale,1),'FM0D99999')
           END 
        || '); --' AS "Command", 
    coalesce(c.cur_scale,s.scale) AS current,
    round(c.scale,6) AS new,
    lpad(to_char(reltuples, 'FM999G999G999G990'),15) AS n_live_tup
FROM 
    (SELECT
            (250000 / nullif(reltuples, 0))::NUMERIC AS scale, -- 250K tuples goal
            (SELECT to_number(option_value,'99.99999') FROM pg_options_to_table(reloptions) WHERE option_name = 'autovacuum_analyze_scale_factor') AS cur_scale,
            relname, relnamespace, relkind, reltuples, oid, reloptions
        FROM pg_class) c
    JOIN pg_namespace n ON c.relnamespace = n.oid,
    (SELECT to_number(current_setting('autovacuum_analyze_scale_factor'),'99.999') AS scale) AS s
WHERE
    c.relkind IN ('r', 'm', 'p') AND  -- Only tables
    c.reltuples > 1000000        AND  -- Only tables > 1M tuples
    c.scale     < s.scale        AND  -- Only adjust WHERE new value < default value
    coalesce(c.cur_scale,s.scale) !=      -- Only adjust WHERE new value != current value
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
