SELECT
    n.nspname AS "Esquema", 
    c.relname AS "Tabela",
    trim(to_char(mxid_age(c.relminmxid),'999G999G999G999')) ||
        CASE 
            WHEN t.relfrozenxid IS NOT NULL 
                THEN ' (T ' || trim(to_char(mxid_age(t.relminmxid),'999G999G999G999')) || ')'
            ELSE '' END AS "Current Age",
    trim(to_char(LEAST (to_number(COALESCE(fmi.option_value, current_setting('vacuum_multixact_freeze_min_age')),'999999999999'),
        to_number(COALESCE(fma.option_value, current_setting('autovacuum_freeze_max_age')),'999999999999') /2),'999G999G999G999')) || 
            CASE WHEN 
                tfmi.option_value IS NOT NULL AND 
                to_number(tfmi.option_value, '999999999999') < to_number(current_setting('autovacuum_multixact_freeze_max_age'),'999999999999')/2
                THEN ' (T ' || trim(to_char(to_number(tfmi.option_value ,'999999999999'),'999G999G999G999')) || ')' 
            ELSE '' END AS "Min Age", 
    trim(to_char(LEAST (to_number(COALESCE(ftb.option_value, current_setting('vacuum_multixact_freeze_table_age')),'999999999999'),
        to_number(COALESCE(fma.option_value, current_setting('autovacuum_multixact_freeze_max_age')),'999999999999') * '0.95'),'999G999G999G999')) || 
            CASE WHEN 
                tftb.option_value IS NOT NULL  AND 
                to_number(tftb.option_value ,'999999999999') < to_number(current_setting('autovacuum_multixact_freeze_max_age'),'999999999999')*'0.95'
                THEN ' (T ' || trim(to_char(to_number(tftb.option_value ,'999999999999'),'999G999G999G999')) || ')' 
            ELSE '' END AS "Table Age", 
    trim(to_char(to_number(COALESCE(fma.option_value, current_setting('autovacuum_multixact_freeze_max_age')), '999999999999'),'999G999G999G999')) ||
            CASE WHEN 
                tfma.option_value IS NOT NULL AND
                to_number(tfma.option_value ,'999999999999') < to_number(current_setting('autovacuum_multixact_freeze_max_age'),'999999999999')
                THEN ' (T ' || trim(to_char(to_number(tfma.option_value ,'999999999999'),'999G999G999G999')) || ')' 
            ELSE '' END AS "Max Age", 
    trim(to_char(to_number(current_setting('vacuum_multixact_failsafe_age'),'999999999999'),'999G999G999G999')) AS "Failsafe Age", 
    pg_size_pretty(pg_table_size(c.oid)) AS "Tamanho"
FROM 
    pg_class c 
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN pg_class t ON t.oid = c.reltoastrelid
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  fmi ON  fmi.option_name = 'autovacuum_multixact_freeze_min_age' 
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  ftb ON  ftb.option_name = 'autovacuum_multixact_freeze_table_age' 
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  fma ON  fma.option_name = 'autovacuum_multixact_freeze_max_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tfmi ON tfmi.option_name = 'autovacuum_multixact_freeze_min_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tftb ON tftb.option_name = 'autovacuum_multixact_freeze_table_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tfma ON tfma.option_name = 'autovacuum_multixact_freeze_max_age' 
WHERE
    c.relkind IN ('r', 'm') AND
    --n.nspname NOT IN ('information_schema', 'pg_catalog') AND
    pg_table_size(c.oid) > 67108864 AND -- > 64MB
    (
        mxid_age(c.relminmxid) >= LEAST (to_number(COALESCE(fmi.option_value,current_setting('vacuum_multixact_freeze_min_age')),'999999999999'),
            to_number(COALESCE(fma.option_value, current_setting('autovacuum_multixact_freeze_max_age')),'999999999999') /2)
    OR
        mxid_age(t.relminmxid) >= LEAST (COALESCE(to_number(tfmi.option_value,'999999999999'), to_number(current_setting('vacuum_freeze_min_age'),'999999999999')),
            to_number(COALESCE(tfma.option_value, current_setting('autovacuum_multixact_freeze_max_age')),'999999999999') /2)
    )
ORDER BY greatest(mxid_age(c.relminmxid), mxid_age(t.relminmxid)) DESC
LIMIT 40;
