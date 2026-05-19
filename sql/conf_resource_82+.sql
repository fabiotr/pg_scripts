SELECT 
    name AS "conf", 
    CASE name 
	WHEN 'effective_cache_size' 	 	THEN pg_size_pretty(setting::bigint * unit_val)
	WHEN 'shared_buffers'       	 	THEN pg_size_pretty(setting::bigint * unit_val)
	WHEN 'temp_buffers'         	 	THEN pg_size_pretty(setting::bigint * unit_val)
	WHEN 'wal_buffers'          	 	THEN CASE setting WHEN '-1' THEN setting ELSE  pg_size_pretty(setting::bigint  * unit_val) END
	WHEN 'work_mem'             	 	THEN pg_size_pretty(setting::bigint * unit_val)
	WHEN 'temp_file_limit'                  THEN pg_size_pretty(setting::bigint * unit_val)
	
	WHEN 'maintenance_work_mem' 	 	THEN pg_size_pretty(setting::bigint * unit_val)
	WHEN 'autovacuum_work_mem'  	 	THEN CASE setting WHEN '-1' THEN setting ELSE pg_size_pretty(setting::bigint * unit_val) END
	WHEN 'vacuum_buffer_usage_limit'        THEN pg_size_pretty(setting::bigint * unit_val)	
	WHEN 'logical_decoding_work_mem' 	THEN pg_size_pretty(setting::bigint * unit_val)
	WHEN 'max_wal_size'         	 	THEN pg_size_pretty(setting::bigint * unit_val) 	
	WHEN 'min_wal_size'         	 	THEN pg_size_pretty(setting::bigint * unit_val)
	WHEN 'checkpoint_completion_target' 	THEN setting
	WHEN 'checkpoint_timeout'		THEN setting || ' ' || unit
    END AS "Value",
    source
FROM (
	SELECT 
	    category, name, setting, source, unit,
	    CASE WHEN unit = 'B' THEN 1
	         WHEN unit = 'kB' THEN 1024
		 WHEN unit = 'MB' THEN 1048576
		 WHEN unit = '8kB' THEN 8192
	         ELSE 1 END AS unit_val
       	FROM pg_settings) AS ss
WHERE name IN (
	'autovacuum_work_mem','vacuum_buffer_usage_limit', 'maintenance_work_mem', 'logical_decoding_work_mem', 'max_wal_size','min_wal_size',
	'shared_buffers','work_mem','effective_cache_size', 'temp_buffers', 'wal_buffers','checkpoint_timeout', 'checkpoint_completion_target','temp_file_limit')
ORDER BY category, name;
