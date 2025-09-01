SELECT
	n.nspname AS "Schema",
	c.relname AS "Table",
    	t.spcname AS "Tablespace", 
	CASE c.relpersistence
        WHEN 'p' THEN 'permanent'
        WHEN 'u' THEN 'unlogged'
        WHEN 't' THEN 'temporary'
    END AS "Persistence",
    pg_size_pretty(pg_total_relation_size(c.oid)) AS "Total Size",
    pg_size_pretty(pg_table_size(c.oid)) AS "Size",
    pg_size_pretty(approx_free_space) AS "Free Size",
    coalesce(fillfactor::integer,100) AS "Fillfactor",
    round(approx_free_percent::numeric,2) AS "% Free",
    round(approx_free_percent::numeric - (100 - coalesce(fillfactor::numeric,100)), 2) AS "% Free - Fillfactor"
FROM 
    pg_class c
    JOIN pg_namespace n  ON n.oid = c.relnamespace
    LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
    LEFT JOIN LATERAL (SELECT option_value AS fillfactor FROM pg_options_to_table(c.reloptions) WHERE option_name = 'fillfactor') f ON true,    
    LATERAL (SELECT * FROM pgstattuple_approx(c.oid)) l
WHERE 
    c.relkind IN ('r','p', 'm','f','')
    AND n.nspname != 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND c.relpages > 100
    AND approx_free_percent::numeric - (100 - coalesce(fillfactor::numeric,100)) > 10
ORDER BY approx_free_space DESC
;
