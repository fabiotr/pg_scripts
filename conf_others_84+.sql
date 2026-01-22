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
    name NOT IN ('autovacuum_work_mem','vacuum_buffer_usage_limit', 'maintenance_work_mem', 'logical_decoding_work_mem', 'max_wal_size','min_wal_size',
                 'shared_buffers','work_mem','effective_cache_size', 'temp_buffers', 'wal_buffers','checkpoint_timeout', 'checkpoint_completion_target') AND
    name NOT IN ('data_directory','config_file', 'hba_file', 'log_directory', 'ident_file','archive_command', 'unix_socket_directories', 'external_pid_file', 'extension_control_path') AND
    name NOT IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename', 'log_file_mode', 'log_rotation_age', 'log_rotation_size', 'log_truncate_on_rotation',
                 'log_min_messages', 'log_min_error_statement', 'log_min_duration_statement', 'log_min_duration_sample', 'log_statement_sample_rate',
                 'log_startup_progress_interval', 'debug_print_parse', 'debug_print_rewritten', 'debug_print_plan', 'debug_pretty_print', 'log_autovacuum_min_duration',
                 'log_checkpoints', 'log_connections', 'log_disconnections', 'log_duration', 'log_error_verbosity', 'log_hostname', 'log_line_prefix', 'log_lock_waits', 
		 'log_lock_failures', 'log_recovery_conflict_waits', 'log_parameter_max_length', 'log_parameter_max_length_on_error', 'log_statement', 'log_replication_commands', 
		 'log_temp_files', 'TimeZone',  'log_timezone', 'lc_messages', 'track_activities', 'track_counts', 'track_functions',  'track_io_timing', 'track_cost_delay_timing', 
		 'track_activity_query_size', 'track_wal_io_timing', 'stats_fetch_consistency', 'compute_query_id', 'log_statement_stats', 'log_parser_stats', 'log_planner_stats', 
		 'log_executor_stats','shared_preload_libraries', 'pg_stat_statements.track', 'pg_stat_statements.track_planning', 'pg_stat_statements.track_utility', 
		 'pg_stat_statements.save', 'pg_stat_statements.max') AND
    name NOT IN ('max_wal_senders', 'max_replication_slots', 'wal_keep_size', 'max_slot_wal_keep_size', 'wal_sender_timeout', 'track_commit_timestamp',
		 'synchronous_standby_names', 'wal_level') AND
    name NOT IN ('restore_command', 'archive_cleanup_command', 'recovery_end_command',
		 'recovery_target', 'recovery_target_name', 'recovery_target_time',
		 'recovery_target_xid', 'recovery_target_lsn', 'recovery_target_inclusive',
		 'recovery_target_timeline', 'recovery_target_action') AND
    name NOT IN ('primary_conninfo', 'primary_slot_name', 'hot_standby', 'max_standby_archive_delay', 'max_standby_streaming_delay', 'wal_receiver_create_temp_slot',
                 'wal_receiver_status_interval', 'hot_standby_feedback', 'wal_receiver_timeout', 'wal_retrieve_retry_interval', 'recovery_min_apply_delay',
                 'sync_replication_slots', 'max_active_replication_origins', 'max_logical_replication_workers', 'max_sync_workers_per_subscription',
                 'max_parallel_apply_workers_per_subscription') AND
    name NOT IN ('ssl', 'ssl_ca_file', 'ssl_cert_file', 'ssl_crl_file', 'ssl_crl_dir', 'ssl_key_file', 'ssl_tls13_ciphers', 'ssl_ciphers', 'ssl_prefer_server_ciphers',
                 'ssl_groups', 'ssl_min_protocol_version', 'ssl_max_protocol_version', 'ssl_dh_params_file', 'ssl_passphrase_command', 'ssl_passphrase_command_supports_reload') AND
    name NOT IN ('authentication_timeout', 'password_encryption', 'scram_iterations', 'md5_password_warnings', 'krb_server_keyfile', 'krb_caseins_users', 'gss_accept_delegation',
                 'oauth_validator_libraries')
ORDER BY category, name;
