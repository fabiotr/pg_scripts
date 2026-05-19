SELECT
    name AS "conf",
    CASE name
	WHEN 'effective_cache_size' 	 	THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'shared_buffers'       	 	THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'temp_buffers'         	 	THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'wal_buffers'          	 	THEN CASE setting WHEN '-1' THEN lpad(setting,8) ELSE  lpad(pg_size_pretty(setting::bigint  * unit_val),7) END
	WHEN 'work_mem'             	 	THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'temp_file_limit'              THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'maintenance_work_mem' 	 	THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'autovacuum_work_mem'  	 	THEN CASE setting WHEN '-1' THEN lpad(setting,8) ELSE lpad(pg_size_pretty(setting::bigint * unit_val),7) END
	WHEN 'vacuum_buffer_usage_limit'    THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'logical_decoding_work_mem' 	THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'max_wal_size'         	 	THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'min_wal_size'         	 	THEN lpad(pg_size_pretty(setting::bigint * unit_val),7)
	WHEN 'checkpoint_completion_target' THEN lpad(setting,7)
	WHEN 'checkpoint_timeout'		    THEN lpad(setting || ' ' || unit,7)
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
