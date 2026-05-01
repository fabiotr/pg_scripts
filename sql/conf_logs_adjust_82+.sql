SELECT
    CASE
        WHEN name = 'log_destination'                   THEN $$log_destination = 'stderr';$$
        WHEN name = 'logging_collector'                 THEN $$logging_collector = ON;$$
        WHEN name = 'log_rotation_age'                  THEN $$log_rotation_age = '1d';$$
        WHEN name = 'log_min_messages'                  THEN $$log_min_messages = 'INFO'$$
        WHEN name = 'log_min_error_statement'           THEN $$log_min_error_statement = 'INFO';$$
        WHEN name = 'log_min_duration_statement'        THEN $$log_min_duration_statement = '1s';$$
        WHEN name = 'debug_print_parse'                 THEN $$debug_print_parse = OFF$$
        WHEN name = 'debug_print_rewritten'             THEN $$debug_print_rewritten = OFF$$
        WHEN name = 'debug_print_plan'                  THEN $$debug_print_plan = ON;$$
        WHEN name = 'debug_pretty_print'                THEN $$debug_pretty_print = ON;$$
        WHEN name = 'log_autovacuum_min_duration'       THEN $$log_autovacuum_min_duration = 0;$$
        WHEN name = 'log_checkpoints'                   THEN $$log_checkpoints = ON;$$
        WHEN name = 'log_connections'                   THEN $$log_connections = ON;$$
        WHEN name = 'log_disconnections'                THEN $$log_disconnections = ON;$$
        WHEN name = 'log_duration'                      THEN $$log_duration = OFF$$
        WHEN name = 'log_error_verbosity'               THEN $$log_error_verbosity = DEFAULT$$
        WHEN name = 'log_hostname'                      THEN $$log_hostname = OFF$$
        WHEN name = 'log_line_prefix'                   THEN $$log_line_prefix = '%t p[%p] l[%l]%q, user=%u, db=%d, client=%h > '$$
        WHEN name = 'log_lock_waits'                    THEN $$log_lock_waits = ON$$
        WHEN name = 'log_lock_failures'                 THEN $$log_lock_failures = ON$$
        WHEN name = 'log_recovery_conflict_waits'       THEN $$log_recovery_conflict_waits = ON$$
        WHEN name = 'log_parameter_max_length'          THEN $$log_parameter_max_length = -1$$
        WHEN name = 'log_parameter_max_length_on_error' THEN $$log_parameter_max_length_on_error = 0$$
        WHEN name = 'log_statement'                     THEN $$log_statement = 'DDL'$$
        WHEN name = 'log_replication_commands'          THEN $$log_replication_commands = ON$$
        WHEN name = 'log_temp_files'                    THEN $$log_temp_files = 0$$
        WHEN name = 'log_timezone'                      THEN $$log_timezone = '$$ || current_setting('TimeZone') || $$'$$
        WHEN name = 'lc_messages'                       THEN $$lc_messages = 'C'$$
        WHEN name = 'track_activities'                  THEN $$track_activities = ON$$
        WHEN name = 'track_activity_query_size'         THEN $track_activity_query_size = 8192$$
        WHEN name = 'track_counts'                      THEN $track_counts = ON$$
        WHEN name = 'track_io_timing'                   THEN $$track_io_timing = ON$$
        WHEN name = 'track_wal_io_timing'               THEN $$track_wal_io_timing = ON$$
        WHEN name = 'track_cost_delay_timing'           THEN $$track_cost_delay_timing = ON$$
        WHEN name = 'track_functions'                   THEN $$track_functions = ALL$$
        WHEN name = 'stats_fetch_consistency'           THEN $$stats_fetch_consistency = 'cache'$$
        WHEN name = 'compute_query_id'                  THEN $$compute_query_id = 'auto'$$
        WHEN name = 'log_statement_stats'               THEN $$log_statement_stats = off$$
        WHEN name = 'log_parser_stats'                  THEN $$log_parser_stats = off$$
        WHEN name = 'log_planner_stats'                 THEN $$log_planner_stats = off$$
        WHEN name = 'log_executor_stats'                THEN $$log_executor_stats = off$$
        WHEN name = 'shared_preload_libraries'          THEN $$shared_preload_libraries = '$$|| CASE WHEN setting = $$$$ THEN $$pg_stat_statements'$$ ELSE setting || $$, pg_stat_statements'$$ END --'
        WHEN name = 'pg_stat_statements.track'          THEN $$pg_stat_statements.track = 'all'$$
        WHEN name = 'pg_stat_statements.track_utility'  THEN $$pg_stat_statements.track_utility = ON$$
        WHEN name = 'pg_stat_statements.track_planning' THEN $$pg_stat_statements.track_planning = ON$$
        WHEN name = 'pg_stat_statements.save'           THEN $$pg_stat_statements.save = ON$$
    END || ' -- 'AS "Command",
    setting AS "value",
    source
FROM pg_settings
WHERE 
        (name = 'log_destination'                   AND source IN ('default', 'configuration file') AND setting != 'stderr') OR
        (name = 'logging_collector'                 AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'log_rotation_age'                  AND source IN ('default', 'configuration file') AND setting != '1440') OR
        (name = 'log_min_messages'                  AND source IN ('default', 'configuration file') AND setting IN ('panic', 'fatal', 'error')) OR
        (name = 'log_min_error_statement'           AND source IN ('default', 'configuration file') AND setting IN ('panic', 'fatal', 'error')) OR
        (name = 'log_min_duration_statement'        AND source IN ('default', 'configuration file') AND setting = '-1') OR
        (name = 'debug_print_parse'                 AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'debug_print_rewritten'             AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'debug_print_plan'                  AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'debug_pretty_print'                AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'log_autovacuum_min_duration'       AND source IN ('default', 'configuration file') AND setting != '0') OR
        (name = 'log_checkpoints'                   AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'log_connections'                   AND source IN ('default', 'configuration file') AND setting IN ('off','')) OR
        (name = 'log_disconnections'                AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'log_duration'                      AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'log_error_verbosity'               AND source IN ('default', 'configuration file') AND setting = 'TERSE') OR
        (name = 'log_hostname'                      AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'log_line_prefix'                   AND source IN ('default', 'configuration file') AND (
            setting NOT LIKE '%%u%' OR  setting NOT LIKE '%%p%'
                OR  (setting NOT LIKE '%%h%' AND setting NOT LIKE '%%r%')
                OR  (setting NOT LIKE '%%t%' AND setting NOT LIKE '%%m%')) OR
        (name = 'log_lock_waits'                    AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'log_lock_failures'                 AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'log_recovery_conflict_waits'       AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'log_parameter_max_length'          AND source IN ('default', 'configuration file') AND setting != '-1') OR
        (name = 'log_parameter_max_length_on_error' AND source IN ('default', 'configuration file') AND setting != '0') OR
        (name = 'log_statement'                     AND source IN ('default', 'configuration file') AND setting != 'ddl') OR
        (name = 'log_replication_commands'          AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'log_temp_files'                    AND source IN ('default', 'configuration file') AND setting != '0') OR
        (name = 'log_timezone'                      AND source IN ('default', 'configuration file') AND setting != current_setting('TimeZone')) OR
        (name = 'lc_messages'                       AND source IN ('default', 'configuration file') AND setting NOT IN ('C', 'C.UTF-8', 'en_US.UTF-8', 'en_US.UTF8', 'C.UTF8')) OR
        (name = 'track_activities'                  AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'track_activity_query_size'         AND source IN ('default', 'configuration file') AND to_number(setting, '99999') < 1024) OR
        (name = 'track_counts'                      AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'track_io_timing'                   AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'track_wal_io_timing'               AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'track_cost_delay_timing'           AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'track_functions'                   AND source IN ('default', 'configuration file') AND setting != 'all') OR
        (name = 'stats_fetch_consistency'           AND source IN ('default', 'configuration file') AND setting != 'cache') OR
        (name = 'compute_query_id'                  AND source IN ('default', 'configuration file') AND setting NOT IN ('auto', 'on')) OR
        (name = 'log_statement_stats'               AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'log_parser_stats'                  AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'log_planner_stats'                 AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'log_executor_stats'                AND source IN ('default', 'configuration file') AND setting != 'off') OR
        (name = 'shared_preload_libraries'          AND source IN ('default', 'configuration file') AND setting NOT LIKE '%pg_stat_statements%') OR
        (name = 'pg_stat_statements.track'          AND source IN ('default', 'configuration file') AND setting != 'all') OR
        (name = 'pg_stat_statements.track_utility'  AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'pg_stat_statements.track_planning' AND source IN ('default', 'configuration file') AND setting != 'on') OR
        (name = 'pg_stat_statements.save'           AND source IN ('default', 'configuration file') AND setting != 'on')
ORDER BY category, name;

