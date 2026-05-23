SELECT 
    i.nspname AS "Schema",
    i.relname AS "Table",
    to_char(i.current_age ,'FM999G999G999G999') || CASE WHEN current_age_toast IS NULL THEN '' ELSE ' (T ' || to_char(current_age_toast,'FM999G999G999G999') || ')' END AS "Current Age",
    to_char(i.min_age     ,'FM999G999G999G999') || CASE WHEN min_age_toast     IS NULL THEN '' ELSE ' (T ' || to_char(min_age_toast    ,'FM999G999G999G999') || ')' END AS "Min Age",
    to_char(i.table_age   ,'FM999G999G999G999') || CASE WHEN table_age_toast   IS NULL THEN '' ELSE ' (T ' || to_char(table_age_toast  ,'FM999G999G999G999') || ')' END AS "Table Age",
    to_char(i.max_age     ,'FM999G999G999G999') || CASE WHEN max_age_toast     IS NULL THEN '' ELSE ' (T ' || to_char(max_age_toast    ,'FM999G999G999G999') || ')' END AS "Max Age",
    to_char(i.failsafe_age,'FM999G999G999G999') AS "Failsafe Age",
    i.size AS "Size",
    CASE 
        WHEN i.current_age <= min_age      AND coalesce(current_age_toast,0) <= coalesce(min_age_toast,   min_age)   THEN '🔵 Nice'
        WHEN i.current_age <= table_age    AND coalesce(current_age_toast,0) <= coalesce(table_age_toast, table_age) THEN '✅ OK'
        WHEN i.current_age <= max_age      AND coalesce(current_age_toast,0) <= coalesce(max_age_toast,   max_age)   THEN '🟡 Atention'
        WHEN i.current_age <= failsafe_age AND coalesce(current_age_toast,0) <= failsafe_age                         THEN '🟠 Warning'
        ELSE                                                                                                              '🔴 Critic'
        END AS "Status"
FROM (
    SELECT
        n.nspname,
        c.relname,
        age(c.relfrozenxid) AS current_age,
        CASE WHEN t.relfrozenxid IS NOT NULL AND c.relfrozenxid != t.relfrozenxid
                THEN age(t.relfrozenxid)
                ELSE NULL END AS current_age_toast,
        LEAST (to_number(COALESCE(fmi.option_value, current_setting('vacuum_freeze_min_age')),'999999999999'),
            to_number(COALESCE(fma.option_value, current_setting('autovacuum_freeze_max_age')),'999999999999') /2) AS min_age,
        CASE WHEN
            tfmi.option_value IS NOT NULL AND
            to_number(tfmi.option_value, '999999999999') < to_number(current_setting('autovacuum_freeze_max_age'),'999999999999')/2
            THEN to_number(tfmi.option_value ,'999999999999')
            ELSE NULL END AS min_age_toast,
        LEAST (to_number(COALESCE(ftb.option_value, current_setting('vacuum_freeze_table_age')),'999999999999'),
            to_number(COALESCE(fma.option_value, current_setting('autovacuum_freeze_max_age')),'999999999999') * '0.95') AS table_age,
        CASE WHEN
            tftb.option_value IS NOT NULL  AND
            to_number(tftb.option_value ,'999999999999') < to_number(current_setting('autovacuum_freeze_max_age'),'999999999999')*'0.95'
            THEN to_number(tftb.option_value ,'999999999999')
            ELSE NULL END AS table_age_toast,
        to_number(COALESCE(fma.option_value, current_setting('autovacuum_freeze_max_age')),'999999999999') AS max_age,
        CASE WHEN
            tfma.option_value IS NOT NULL AND
            to_number(tfma.option_value ,'999999999999') < to_number(current_setting('autovacuum_freeze_max_age'),'999999999999')
            THEN to_number(tfma.option_value ,'999999999999')
            ELSE NULL END AS max_age_toast,
        to_number(current_setting('vacuum_failsafe_age'),'999999999999') AS failsafe_age,
        pg_size_pretty(pg_table_size(c.oid)) AS size
    FROM
        pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        LEFT JOIN pg_class t ON t.oid = c.reltoastrelid
        LEFT JOIN pg_options_to_table(c.reloptions)  AS  fmi ON  fmi.option_name = 'autovacuum_freeze_min_age'
        LEFT JOIN pg_options_to_table(c.reloptions)  AS  ftb ON  ftb.option_name = 'autovacuum_freeze_table_age'
        LEFT JOIN pg_options_to_table(c.reloptions)  AS  fma ON  fma.option_name = 'autovacuum_freeze_max_age'
        LEFT JOIN pg_options_to_table(t.reloptions)  AS tfmi ON tfmi.option_name = 'autovacuum_freeze_min_age'
        LEFT JOIN pg_options_to_table(t.reloptions)  AS tftb ON tftb.option_name = 'autovacuum_freeze_table_age'
        LEFT JOIN pg_options_to_table(t.reloptions)  AS tfma ON tfma.option_name = 'autovacuum_freeze_max_age'
    WHERE
        c.relkind IN ('r', 'm', 'p') AND
        pg_table_size(c.oid) > 1024576 AND
        (age(c.relfrozenxid) >= to_number(COALESCE(fmi.option_value,  current_setting('vacuum_freeze_min_age')),'999999999999') /2 OR
         age(t.relfrozenxid) >= to_number(COALESCE(tfmi.option_value, current_setting('vacuum_freeze_min_age')),'999999999999') /2)
    ORDER BY greatest(age(c.relfrozenxid), age(t.relfrozenxid)) DESC
    LIMIT 40) AS i;
