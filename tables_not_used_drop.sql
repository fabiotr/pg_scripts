SELECT  'DROP TABLE ' || schemaname || '.' ||  relname || ' CASCADE;'
    FROM pg_stat_user_tables 
    WHERE 
        seq_scan + coalesce(idx_scan, 0) < 10 AND
        schemaname NOT LIKE 'pg_%'
    ORDER BY schemaname, relname;
