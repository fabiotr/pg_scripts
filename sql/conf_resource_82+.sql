SELECT 
--    category, 
    name AS "conf", 
    CASE name 
	WHEN 'effective_cache_size' 	 	THEN pg_size_pretty(setting::bigint * current_setting('block_size')::bigint)
	WHEN 'shared_buffers'       	 	THEN pg_size_pretty(setting::bigint * current_setting('block_size')::bigint)
	WHEN 'temp_buffers'         	 	THEN pg_size_pretty(setting::bigint * current_setting('block_size')::bigint)
	WHEN 'wal_buffers'          	 	THEN CASE setting WHEN '-1' THEN setting ELSE  pg_size_pretty(setting::bigint  * current_setting('block_size')::bigint) END
	WHEN 'work_mem'             	 	THEN pg_size_pretty(setting::bigint * 1024)
	WHEN 'maintenance_work_mem' 	 	THEN pg_size_pretty(setting::bigint * 1024)
	WHEN 'autovacuum_work_mem'  	 	THEN CASE setting WHEN '-1' THEN setting ELSE pg_size_pretty(setting::bigint * 1024) END
	WHEN 'vacuum_buffer_usage_limit'        THEN pg_size_pretty(setting::bigint * 1024)	
	WHEN 'logical_decoding_work_mem' 	THEN pg_size_pretty(setting::bigint * 1024)
	WHEN 'max_wal_size'         	 	THEN pg_size_pretty(setting::bigint * 1024 * 1024) 	
	WHEN 'min_wal_size'         	 	THEN pg_size_pretty(setting::bigint * 1024 * 1024)
	WHEN 'checkpoint_completion_target' 	THEN setting
	WHEN 'checkpoint_timeout'		THEN setting || unit
    END AS "Value",
    source
FROM pg_settings
WHERE name IN (
	'autovacuum_work_mem','vacuum_buffer_usage_limit', 'maintenance_work_mem', 'logical_decoding_work_mem', 'max_wal_size','min_wal_size',
	'shared_buffers','work_mem','effective_cache_size', 'temp_buffers', 'wal_buffers','checkpoint_timeout', 'checkpoint_completion_target')
ORDER BY category, name;
