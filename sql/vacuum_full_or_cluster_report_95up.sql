-- CLUSTER OR VACUUM FULL 
SELECT 
    CASE 
        WHEN c.relhasindex AND i.idx_scan > 0 AND (t.spcname != 'pg_global' OR t.spcname IS NULL)
            THEN 'CLUSTER VERBOSE '     || quote_ident(n.nspname) || '.' || quote_ident(c.relname) || ' USING ' || quote_ident(i.indexrelname) || '; --'
            ELSE 'VACUUM FULL VERBOSE ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) || '; --'
    END AS command
FROM 
    pg_class c
    JOIN pg_namespace n  ON n.oid = c.relnamespace
    LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
    LEFT JOIN (
        -- Most used index per table. CLUSTER rejects partial indexes, so they are skipped
        SELECT DISTINCT ON (s.relid) s.relid, s.indexrelname, s.idx_scan
            FROM
                pg_stat_all_indexes s
                JOIN pg_index x ON x.indexrelid = s.indexrelid
            WHERE x.indpred IS NULL
            ORDER BY s.relid, s.idx_scan DESC, s.indexrelname) i ON i.relid = c.oid
    LEFT JOIN LATERAL (SELECT option_value AS fillfactor FROM pg_options_to_table(c.reloptions) WHERE option_name = 'fillfactor') o ON TRUE,
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

