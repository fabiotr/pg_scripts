SELECT 
    --category, 
    name AS "conf", 
    setting AS "value", 
    boot_val AS "default", 
    unit
FROM pg_settings
WHERE
    source = 'configuration file' AND 
    setting != boot_val AND
    name NOT IN ('autovacuum_work_mem','maintenance_work_mem', 'logical_decoding_work_mem', 'max_wal_size','min_wal_size','shared_buffers','work_mem','effective_cache_size', 
	'checkpoint_completion_target', 'checkpoint_timeout') AND
    name NOT IN ('data_directory','config_file', 'hba_file', 'log_directory', 'ident_file','archive_command', 'unix_socket_directories', 'external_pid_file') AND
    name NOT IN ('lc_messages', 'shared_preload_libraries', 'ssl_ciphers', 'krb_server_keyfile',
 	'log_destination', 'logging_collector', 'log_directory', 'log_filename', 'log_file_mode', 'log_rotation_age', 'log_rotation_size', 'log_truncate_on_rotation',
        'log_min_messages', 'log_min_error_statement', 'log_min_duration_statement', 'log_min_duration_sample', 'log_statement_sample_rate',
        'log_startup_progress_interval', 'debug_print_parse', 'debug_print_rewritten', 'debug_print_plan', 'debug_pretty_print', 'log_autovacuum_min_duration',
        'log_checkpoints', 'log_connections', 'log_disconnections', 'log_duration', 'log_error_verbosity', 'log_hostname', 'log_line_prefix', 'log_lock_waits',
        'log_recovery_conflict_waits', 'log_parameter_max_length', 'log_parameter_max_length_on_error', 'log_statement', 'log_replication_commands', 'log_temp_files',
        'TimeZone',  'log_timezone', 'lc_messages', 'track_activities', 'track_counts', 'track_functions',  'track_io_timing', 'track_activity_query_size',
        'track_wal_io_timing', 'stats_fetch_consistency',
        'compute_query_id', 'log_statement_stats', 'log_parser_stats', 'log_planner_stats', 'log_executor_stats',
        'shared_preload_libraries', 'cluster_name','ssl_cert_file', 'ssl_key_file')
ORDER BY category, name;
