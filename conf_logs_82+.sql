\set QUIET on
\timing off
SELECT
    CASE
        WHEN name = 'log_destination'               	AND source IN ('default', 'configuration file') AND setting = 'stderr'                          THEN 'OK'
	WHEN name = 'logging_collector'             	AND source IN ('default', 'configuration file')                                                 THEN '--'
        WHEN name = 'log_directory'                 	AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_filename'                  	AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_file_mode'                 	AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_rotation_age'              	AND source IN ('default', 'configuration file') AND setting = '1440'                            THEN 'OK'
	WHEN name = 'log_rotation_size'             	AND source IN ('default', 'configuration file') AND setting != '0'                              THEN 'OK'
	WHEN name = 'log_truncate_on_rotation'		AND source IN ('default', 'configuration file')                                                 THEN '--'
		
	WHEN name = 'log_min_messages'              	AND source IN ('default', 'configuration file') AND setting NOT IN ('panic', 'fatal', 'error')  THEN 'OK'
	WHEN name = 'log_min_error_statement'       	AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_min_duration_statement'    	AND source IN ('default', 'configuration file') AND setting != '-1'                             THEN 'OK'
	WHEN name = 'log_min_duration_sample'       	AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_statement_sample_rate'     	AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_transaction_sample_rate'   	AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_startup_progress_interval' 	AND source IN ('default', 'configuration file')                                                 THEN '--'
		
	WHEN name = 'debug_print_parse'             	AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK'
	WHEN name = 'debug_print_rewritten'         	AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK'
	WHEN name = 'debug_print_plan'              	AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK'
	WHEN name = 'debug_pretty_print'            	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK' 
	WHEN name = 'log_autovacuum_min_duration'   	AND source IN ('default', 'configuration file') AND setting = '0'                               THEN 'OK'
	WHEN name = 'log_checkpoints'               	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
	WHEN name = 'log_connections'               	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
        WHEN name = 'log_disconnections'            	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
	WHEN name = 'log_duration'                  	AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK'
	WHEN name = 'log_error_verbosity'           	AND source IN ('default', 'configuration file') AND setting != 'TERSE'                          THEN 'OK'
	WHEN name = 'log_hostname'                  	AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK'
	WHEN name = 'log_line_prefix'               	AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_lock_waits'                	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
        WHEN name = 'log_lock_failures'                 AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
	WHEN name = 'log_recovery_conflict_waits'   	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
	WHEN name = 'log_parameter_max_length'      	AND source IN ('default', 'configuration file') AND setting = '-1'                              THEN 'OK'
	WHEN name = 'log_parameter_max_length_on_error' AND source IN ('default', 'configuration file') AND setting = '0'                               THEN 'OK'
	WHEN name = 'log_statement'                 	AND source IN ('default', 'configuration file') AND setting = 'ddl'                             THEN 'OK'
	WHEN name = 'log_replication_commands'          AND source IN ('default', 'configuration file')                                                 THEN '--'
	WHEN name = 'log_temp_files'                	AND source IN ('default', 'configuration file') AND setting = '0'                               THEN 'OK'

	WHEN name = 'TimeZone'                      	AND source IN ('default', 'configuration file')                                                 THEN '--'
        WHEN name = 'log_timezone'                  	AND source IN ('default', 'configuration file') AND setting = current_setting('TimeZone')       THEN 'OK'
        WHEN name = 'lc_messages'                   	AND source IN ('default', 'configuration file') AND setting IN ('C', 'C.UTF-8', 'en_US.UTF-8')  THEN 'OK'

	WHEN name = 'track_activities'              	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
        WHEN name = 'track_activity_query_size'     	AND source IN ('default', 'configuration file') AND to_number(setting, '99999') >= 1024         THEN 'OK'
	WHEN name = 'track_counts'                  	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
        WHEN name = 'track_io_timing'               	AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
	WHEN name = 'track_wal_io_timing'               AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
	WHEN name = 'track_cost_delay_timing'           AND source IN ('default', 'configuration file') AND setting = 'on'                              THEN 'OK'
	WHEN name = 'track_functions'               	AND source IN ('default', 'configuration file') AND setting = 'all'                             THEN 'OK'
	WHEN name = 'stats_fetch_consistency'           AND source IN ('default', 'configuration file') AND setting = 'cache'                           THEN 'OK'
       
	WHEN name = 'compute_query_id'                  AND source IN ('default', 'configuration file') AND setting IN ('auto', 'on')                   THEN 'OK'
	WHEN name = 'log_statement_stats'               AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK'
	WHEN name = 'log_parser_stats'                  AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK'
	WHEN name = 'log_planner_stats'                 AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK' 
	WHEN name = 'log_executor_stats'                AND source IN ('default', 'configuration file') AND setting = 'off'                             THEN 'OK'
	
	WHEN name = 'shared_preload_libraries'          AND source IN ('default', 'configuration file') AND setting LIKE '%pg_stat_statements%'         THEN 'OK'
	WHEN name = 'pg_stat_statements.max'		AND source IN ('default', 'configuration file')							THEN '--'
	WHEN name = 'pg_stat_statements.track'		AND source IN ('default', 'configuration file') AND setting = 'all'				THEN 'OK'
	WHEN name = 'pg_stat_statements.track_utility'  AND source IN ('default', 'configuration file') AND setting = 'on'				THEN 'OK'
	WHEN name = 'pg_stat_statements.track_planning' AND source IN ('default', 'configuration file') AND setting = 'on'				THEN 'OK'
	WHEN name = 'pg_stat_statements.save'		AND source IN ('default', 'configuration file') AND setting = 'on'				THEN 'OK'
	ELSE '<!!>'
    END AS "OK",
    name AS "conf",
    setting AS "value",
    source
FROM pg_settings
WHERE name IN (
	'log_destination', 'logging_collector', 'log_directory', 'log_filename', 'log_file_mode', 'log_rotation_age', 'log_rotation_size', 'log_truncate_on_rotation', 
	'log_min_messages', 'log_min_error_statement', 'log_min_duration_statement', 'log_min_duration_sample', 'log_statement_sample_rate', 
	'log_startup_progress_interval', 'debug_print_parse', 'debug_print_rewritten', 'debug_print_plan', 'debug_pretty_print', 'log_autovacuum_min_duration', 
	'log_checkpoints', 'log_connections', 'log_disconnections', 'log_duration', 'log_error_verbosity', 'log_hostname', 'log_line_prefix', 'log_lock_waits', 'log_lock_failures',
	'log_recovery_conflict_waits', 'log_parameter_max_length', 'log_parameter_max_length_on_error', 'log_statement', 'log_replication_commands', 'log_temp_files',
	'TimeZone',  'log_timezone', 'lc_messages', 'track_activities', 'track_counts', 'track_functions',  'track_io_timing', 'track_cost_delay_timing', 'track_activity_query_size',
	'track_wal_io_timing', 'stats_fetch_consistency', 
	'compute_query_id', 'log_statement_stats', 'log_parser_stats', 'log_planner_stats', 'log_executor_stats', 
	'shared_preload_libraries', 'pg_stat_statements.track', 'pg_stat_statements.track_planning', 'pg_stat_statements.track_utility', 'pg_stat_statements.save', 'pg_stat_statements.max')
ORDER BY category, name;
\timing on
\set QUIET off
