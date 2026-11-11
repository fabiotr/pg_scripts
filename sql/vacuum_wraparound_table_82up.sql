SELECT
    n.nspname AS "Schema", 
    c.relname AS "Table",
    lpad(to_char(age(c.relfrozenxid),'FM999G999G999G999'), 16) ||
        CASE 
            WHEN t.relfrozenxid IS NOT NULL 
                THEN ' (T ' || to_char(age(t.relfrozenxid),'FM999G999G999G999') || ')'
            ELSE '' END AS "Current Age",
    lpad(to_char(LEAST (to_number(COALESCE(c.fmi, current_setting('vacuum_freeze_min_age')),'999999999999'),
        to_number(COALESCE(c.fma, current_setting('autovacuum_freeze_max_age')),'999999999999') /2),'FM999G999G999G999'), 16) || 
            CASE WHEN 
                t.fmi IS NOT NULL AND 
                to_number(t.fmi, '999999999999') < to_number(current_setting('autovacuum_freeze_max_age'),'999999999999')/2
                THEN ' (T ' || to_char(to_number(t.fmi ,'999999999999'),'FM999G999G999G999') || ')' 
            ELSE '' END AS "Min Age", 
    lpad(to_char(LEAST (to_number(COALESCE(c.ftb, current_setting('vacuum_freeze_table_age')),'999999999999'),
        to_number(COALESCE(c.fma, current_setting('autovacuum_freeze_max_age')),'999999999999') * '0.95'),'FM999G999G999G999'), 16) || 
            CASE WHEN 
                t.ftb IS NOT NULL  AND 
                to_number(t.ftb ,'999999999999') < to_number(current_setting('autovacuum_freeze_max_age'),'999999999999')*'0.95'
                THEN ' (T ' || to_char(to_number(t.ftb ,'999999999999'),'FM999G999G999G999') || ')' 
            ELSE '' END AS "Table Age", 
    lpad(to_char(to_number(COALESCE(c.fma, current_setting('autovacuum_freeze_max_age')), '999999999999'),'FM999G999G999G999'), 16) ||
            CASE WHEN 
                t.fma IS NOT NULL AND
                to_number(t.fma ,'999999999999') < to_number(current_setting('autovacuum_freeze_max_age'),'999999999999')
                THEN ' (T ' || to_char(to_number(t.fma ,'999999999999'),'FM999G999G999G999') || ')' 
            ELSE '' END AS "Max Age", 
    lpad(pg_size_pretty((pg_relation_size(c.oid) + coalesce(pg_relation_size(t.oid), 0))), 11) AS "Size"
FROM 
    -- reloptions read straight from the array: pg_options_to_table() only exists from 8.4,
    -- and a function joined to c would be an implicit LATERAL (9.3+)
    (SELECT r.oid, r.relname, r.relnamespace, r.relkind, r.relfrozenxid, r.reltoastrelid,
            (SELECT substr(r.reloptions[i], length('autovacuum_freeze_min_age=') + 1) FROM generate_series(1, array_upper(r.reloptions, 1)) AS i
                WHERE r.reloptions[i] LIKE 'autovacuum_freeze_min_age=%') AS fmi,
            (SELECT substr(r.reloptions[i], length('autovacuum_freeze_table_age=') + 1) FROM generate_series(1, array_upper(r.reloptions, 1)) AS i
                WHERE r.reloptions[i] LIKE 'autovacuum_freeze_table_age=%') AS ftb,
            (SELECT substr(r.reloptions[i], length('autovacuum_freeze_max_age=') + 1) FROM generate_series(1, array_upper(r.reloptions, 1)) AS i
                WHERE r.reloptions[i] LIKE 'autovacuum_freeze_max_age=%') AS fma
        FROM pg_class r) c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN (SELECT r.oid, r.relname, r.relnamespace, r.relkind, r.relfrozenxid, r.reltoastrelid,
            (SELECT substr(r.reloptions[i], length('autovacuum_freeze_min_age=') + 1) FROM generate_series(1, array_upper(r.reloptions, 1)) AS i
                WHERE r.reloptions[i] LIKE 'autovacuum_freeze_min_age=%') AS fmi,
            (SELECT substr(r.reloptions[i], length('autovacuum_freeze_table_age=') + 1) FROM generate_series(1, array_upper(r.reloptions, 1)) AS i
                WHERE r.reloptions[i] LIKE 'autovacuum_freeze_table_age=%') AS ftb,
            (SELECT substr(r.reloptions[i], length('autovacuum_freeze_max_age=') + 1) FROM generate_series(1, array_upper(r.reloptions, 1)) AS i
                WHERE r.reloptions[i] LIKE 'autovacuum_freeze_max_age=%') AS fma
        FROM pg_class r) t ON t.oid = c.reltoastrelid
WHERE
    c.relkind IN ('r', 'm') AND
    --n.nspname NOT IN ('information_schema', 'pg_catalog') AND
    (pg_relation_size(c.oid) + coalesce(pg_relation_size(t.oid), 0)) > 67108864 AND -- > 64MB
    (
        age(c.relfrozenxid) >= LEAST (to_number(COALESCE(c.fmi,current_setting('vacuum_freeze_min_age')),'999999999999'),
            to_number(COALESCE(c.fma, current_setting('autovacuum_freeze_max_age')),'999999999999') /2)
    OR
        age(t.relfrozenxid) >= LEAST (to_number(COALESCE(t.fmi, current_setting('vacuum_freeze_min_age')),'999999999999'),
            to_number(COALESCE(t.fma, current_setting('autovacuum_freeze_max_age')),'999999999999') /2)
    )
ORDER BY greatest(age(c.relfrozenxid), age(t.relfrozenxid)) DESC
LIMIT 40;
