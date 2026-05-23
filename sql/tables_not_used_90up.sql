SELECT 
	schemaname AS "Schema", 
	relname AS "Table", 
	seq_scan AS "Seq scan", 
	idx_scan AS "Index scan", 
	n_live_tup AS "Rows", 
	pg_size_pretty(pg_table_size(relid)) AS  "Size"
    FROM pg_stat_user_tables 
    WHERE 
        seq_scan + coalesce(idx_scan, 0) < 10 AND
        schemaname NOT LIKE 'pg_%'
    ORDER BY schemaname, relname;
