SELECT format('VACUUM FULL VERBOSE ANALYZE %I.%I;', schemaname, relname) FROM pg_stat_sys_tables WHERE schemaname = 'pg_catalog' \gexec
