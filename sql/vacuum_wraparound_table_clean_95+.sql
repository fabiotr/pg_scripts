SELECT 
    'VACUUM ' || n.nspname || '.' || c.relname || '; --' AS command,
    greatest(age(c.relfrozenxid), age(t.relfrozenxid)) AS "Current Age",
    pg_size_pretty(pg_table_size(c.oid)) AS "Size"
FROM 
    pg_class c 
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN pg_class t ON t.oid = c.reltoastrelid
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  ftb ON  ftb.option_name = 'autovacuum_freeze_table_age' 
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  fma ON  fma.option_name = 'autovacuum_freeze_max_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tftb ON tftb.option_name = 'autovacuum_freeze_table_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tfma ON tfma.option_name = 'autovacuum_freeze_max_age' 
WHERE
    c.relkind IN ('r', 'm') AND
    --n.nspname NOT IN ('information_schema', 'pg_catalog') AND
    pg_table_size(c.oid) > 67108864 AND -- > 64MB
    (
        age(c.relfrozenxid) >= LEAST (to_number(COALESCE(ftb.option_value,current_setting('vacuum_freeze_table_age')),'999999999999'),
            to_number(COALESCE(fma.option_value, current_setting('autovacuum_freeze_max_age')),'999999999999') * '0.95')
    OR
        age(t.relfrozenxid) >= LEAST (to_number(COALESCE(tftb.option_value, current_setting('vacuum_freeze_table_age')),'999999999999'),
            to_number(COALESCE(tfma.option_value, current_setting('autovacuum_freeze_max_age')),'999999999999') * '0.95')
    )
UNION
SELECT 
    'VACUUM ' || n.nspname || '.' || c.relname || '; --' AS command,
    greatest(mxid_age(c.relminmxid), mxid_age(t.relminmxid)) AS "Current Age",
    pg_size_pretty(pg_table_size(c.oid)) AS "Size"
FROM 
    pg_class c 
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN pg_class t ON t.oid = c.reltoastrelid
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  ftb ON  ftb.option_name = 'autovacuum_multixact_freeze_table_age' 
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  fma ON  fma.option_name = 'autovacuum_multixact_freeze_max_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tftb ON tftb.option_name = 'autovacuum_multixact_freeze_table_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tfma ON tfma.option_name = 'autovacuum_multixact_freeze_max_age' 
WHERE
    c.relkind IN ('r', 'm') AND
    --n.nspname NOT IN ('information_schema', 'pg_catalog') AND
    pg_table_size(c.oid) > 67108864 AND -- > 64MB
    (
        mxid_age(c.relminmxid) >= LEAST (to_number(COALESCE(ftb.option_value,current_setting('vacuum_multixact_freeze_table_age')),'999999999999'),
            to_number(COALESCE(fma.option_value, current_setting('autovacuum_multixact_freeze_max_age')),'999999999999') * '0.95')
    OR
        mxid_age(t.relminmxid) >= LEAST (to_number(COALESCE(tftb.option_value,current_setting('vacuum_multixact_freeze_table_age')),'999999999999'),
            to_number(COALESCE(tfma.option_value, current_setting('autovacuum_multixact_freeze_max_age')),'999999999999') * '0.95')
    )
ORDER BY 2 DESC;
