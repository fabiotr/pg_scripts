SELECT 
    t.spcname AS "Tbs",
    n.nspname AS "Schema",
    c.relname AS "Name",
    CASE c.relkind 
        WHEN 'r' THEN 'table' 
        WHEN 'm' THEN 'materialized view' 
        WHEN 'p' THEN 'partition table' 
        END AS "Type",
    pg_get_userbyid(c.relowner) AS "Owner",
    pg_size_pretty(pg_total_relation_size(c.oid)) AS "Total Size",
    pg_size_pretty(pg_table_size(c.oid)) AS "Size",
    ltrim(to_char(c.reltuples,'999G999G999G999G999')) AS "Rows",
    pg_size_pretty(trunc(pg_table_size(c.oid) / c.reltuples)::numeric) AS "Avg Row Size",
    pg_size_pretty(approx_free_space) AS "Free Size",
    round(approx_free_percent::numeric,2) AS "% Free"
FROM pg_class c
     LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace,
     LATERAL (SELECT * FROM pgstattuple_approx(c.oid)) l
WHERE c.relkind IN ('r','p', 'm','')
      AND c.relpersistence = 'u'
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_toast'
      --AND pg_catalog.pg_table_is_visible(c.oid)
--ORDER BY approx_free_space DESC
ORDER BY c.relpages DESC
LIMIT 20;

