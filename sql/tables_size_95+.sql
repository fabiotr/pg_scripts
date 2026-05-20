SELECT
    coalesce(t.spcname, nullif(current_setting('default_tablespace'),''), 'pg_default') AS "Tablespace",
    n.nspname AS "Schema",
    c.relname AS "Name",
    CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'm' THEN 'materialized view'
        WHEN 'p' THEN 'partition table'
        END AS "Type",
    CASE c.relpersistence
        WHEN 'p' THEN 'permanent'
        WHEN 'u' THEN 'unlogged'
    END AS persistence,
    pg_get_userbyid(c.relowner) AS "Owner",
    --c.relpages,
    lpad(pg_size_pretty(pg_total_relation_size(c.oid)),7) AS "Total Size",
    lpad(pg_size_pretty(pg_table_size(c.oid)),7)          AS "Size",
    lpad(to_char(c.reltuples,'FM999G999G999G999G999'),15) AS "Rows",
    pg_size_pretty(trunc(pg_table_size(c.oid) / nullif(c.reltuples,0))::numeric) AS "Avg Row Size"
FROM pg_class c
    LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
        c.relkind IN ('r', 'm','')
    AND c.relpersistence != 'temporary'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND pg_table_is_visible(c.oid)
ORDER BY pg_table_size(c.oid) DESC
LIMIT 20;
