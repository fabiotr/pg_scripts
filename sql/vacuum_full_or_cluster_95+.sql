-- CLUSTER OR VACUUM FULL 
SELECT 
    CASE 
        WHEN c.relhasindex AND i.idx_scan > 0 AND (t.spcname != 'pg_global' OR t.spcname IS NULL)
            THEN 'CLUSTER VERBOSE "'     || n.nspname || '"."' || c.relname || '" USING "' || i.indexrelname || '"; --'
        ELSE     'VACUUM FULL VERBOSE "' || n.nspname || '"."' || c.relname || '"; --'
    END AS command,
    CASE c.relpersistence
        WHEN 'p' THEN 'permanent'
        WHEN 'u' THEN 'unlogged'
        WHEN 't' THEN 'temporary'
    END AS persistence,
    --pg_size_pretty(pg_total_relation_size(c.oid)) AS "Total Size",
    pg_size_pretty(pg_table_size(c.oid)) AS "Size",
    pg_size_pretty(approx_free_space) AS "Free Size",
    --approx_free_space AS "Free Size'",
    coalesce(fillfactor::integer,100) AS "Fillfactor",
    round(approx_free_percent::numeric,2) AS "% Free",
    round(approx_free_percent::numeric - (100 - coalesce(fillfactor::numeric,100)), 2) AS "% Free - Fillfactor"
FROM 
    pg_class c
    JOIN pg_namespace n  ON n.oid = c.relnamespace
    LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
    LEFT JOIN (
        SELECT i.relid, i.indexrelname, i.idx_scan 
            FROM 
                (SELECT relid, max(idx_scan) AS idx_scan FROM pg_stat_all_indexes i GROUP BY relid) AS s
                JOIN pg_stat_all_indexes i ON i.relid = s.relid AND i.idx_scan = s.idx_scan) i ON i.relid = c.oid
    LEFT JOIN LATERAL (SELECT option_value AS fillfactor FROM pg_options_to_table(c.reloptions) WHERE option_name = 'fillfactor') o ON true,
    LATERAL (SELECT * FROM pgstattuple_approx(c.oid)) l
WHERE 
        c.relkind IN ('r','p', 'm','f','')
    AND c.relpersistence != 'temporary'
    AND n.nspname != 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND c.relpages > 100
    AND approx_free_percent - (100 - coalesce(fillfactor::numeric,100)) > 20
ORDER BY approx_free_space DESC
;

