SELECT 
    'VACUUM ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) || '; --' AS command,
    greatest(age(c.relfrozenxid), age(t.relfrozenxid)) AS "Current Age",
    lpad(pg_size_pretty(pg_table_size(c.oid)),7) AS "Size"
FROM 
    pg_class c 
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN pg_class t ON t.oid = c.reltoastrelid
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  ftb ON  ftb.option_name = 'autovacuum_freeze_table_age' 
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  fma ON  fma.option_name = 'autovacuum_freeze_max_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tftb ON tftb.option_name = 'autovacuum_freeze_table_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tfma ON tfma.option_name = 'autovacuum_freeze_max_age' 
WHERE
    c.relkind IN ('r', 'm', 'p') AND
    pg_table_size(c.oid) > 1048576 AND 
    (
        age(c.relfrozenxid) >= LEAST (to_number(COALESCE(ftb.option_value,current_setting('vacuum_freeze_table_age')),'999999999999'),
            to_number(COALESCE(fma.option_value, current_setting('autovacuum_freeze_max_age')),'999999999999') * '0.95')
    OR
        age(t.relfrozenxid) >= LEAST (to_number(COALESCE(tftb.option_value, current_setting('vacuum_freeze_table_age')),'999999999999'),
            to_number(COALESCE(tfma.option_value, current_setting('autovacuum_freeze_max_age')),'999999999999') * '0.95')
    )
UNION
SELECT 
    'VACUUM ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) || '; --' AS command,
    greatest(mxid_age(c.relminmxid), mxid_age(t.relminmxid)) AS "Current Age",
    lpad(pg_size_pretty(pg_table_size(c.oid)),7) AS "Size"
FROM 
    pg_class c 
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN pg_class t ON t.oid = c.reltoastrelid
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  ftb ON  ftb.option_name = 'autovacuum_multixact_freeze_table_age' 
    LEFT JOIN pg_options_to_table(c.reloptions)  AS  fma ON  fma.option_name = 'autovacuum_multixact_freeze_max_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tftb ON tftb.option_name = 'autovacuum_multixact_freeze_table_age' 
    LEFT JOIN pg_options_to_table(t.reloptions)  AS tfma ON tfma.option_name = 'autovacuum_multixact_freeze_max_age' 
WHERE
    c.relkind IN ('r', 'm', 'p') AND
    pg_table_size(c.oid) > 1048576 AND
    (
        mxid_age(c.relminmxid) >= LEAST (to_number(COALESCE(ftb.option_value,current_setting('vacuum_multixact_freeze_table_age')),'999999999999'),
            to_number(COALESCE(fma.option_value, current_setting('autovacuum_multixact_freeze_max_age')),'999999999999') * '0.95')
    OR
        mxid_age(t.relminmxid) >= LEAST (to_number(COALESCE(tftb.option_value,current_setting('vacuum_multixact_freeze_table_age')),'999999999999'),
            to_number(COALESCE(tfma.option_value, current_setting('autovacuum_multixact_freeze_max_age')),'999999999999') * '0.95')
    )
ORDER BY 2 DESC;
