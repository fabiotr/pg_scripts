SELECT
    coalesce(t.spcname, nullif(current_setting('default_tablespace'),''), 'pg_default') AS "Tablespace",
    n.nspname AS "Schema",
    c.relname AS "Name",
    CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'm' THEN 'materialized view'
        WHEN 'p' THEN 'partition table'
        END AS "Type",
    pg_get_userbyid(c.relowner) AS "Owner",
    lpad(pg_size_pretty(pg_total_relation_size(c.oid)),7) AS "Total Size",
    lpad(pg_size_pretty(pg_table_size(c.oid)),7)          AS "Size",
    lpad(to_char(c.reltuples,'FM999G999G999G999G999'),15) AS "Rows",
    pg_size_pretty(trunc(pg_table_size(c.oid) / c.reltuples)::numeric) AS "Avg Row Size"
FROM pg_class c
     LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','p', 'm','')
      AND c.relpersistence = 'u'
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_toast'
      AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY pg_table_size(c.oid) DESC
LIMIT 20;
