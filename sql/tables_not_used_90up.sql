SELECT 
	schemaname AS "Schema", 
	relname AS "Table", 
	coalesce(seq_scan,0) + coalesce(idx_scan,0) AS "Scan", 
	n_live_tup AS "Rows", 
	pg_size_pretty(pg_table_size(relid)) AS  "Size"
    FROM pg_stat_user_tables 
    WHERE 
        coalesce(seq_scan,0) + coalesce(idx_scan, 0) = g AND
        schemaname NOT LIKE 'pg_%'
    ORDER BY schemaname, relname;
