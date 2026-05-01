SELECT
    CASE
        WHEN name = 'log_destination'                   THEN $$ALTER SYSTEM SET log_destination = 'stderr';$$
        WHEN name = 'logging_collector'                 THEN $$ALTER SYSTEM SET logging_collector = ON;$$
        WHEN name = 'log_rotation_age'                  THEN $$ALTER SYSTEM SET log_rotation_age = '1d';$$
        WHEN name = 'log_min_messages'                  THEN $$ALTER SYSTEM SET log_min_messages = 'INFO'$$
        WHEN name = 'log_min_error_statement'           THEN $$ALTER SYSTEM SET log_min_error_statement = 'INFO';$$
        WHEN name = 'log_min_duration_statement'        THEN $$ALTER SYSTEM SET log_min_duration_statement = '1s';$$
        WHEN name = 'debug_print_parse'                 THEN $$ALTER SYSTEM RESET debug_print_parse;$$
        WHEN name = 'debug_print_rewritten'             THEN $$ALTER SYSTEM RESET debug_print_rewritten;$$
        WHEN name = 'debug_print_plan'                  THEN $$ALTER SYSTEM SET debug_print_plan = ON;$$
        WHEN name = 'debug_pretty_print'                THEN $$ALTER SYSTEM SET debug_pretty_print = ON;$$
        WHEN name = 'log_autovacuum_min_duration'       THEN $$ALTER SYSTEM SET log_autovacuum_min_duration = 0;$$
        WHEN name = 'log_checkpoints'                   THEN $$ALTER SYSTEM SET log_checkpoints = ON;$$
        WHEN name = 'log_connections'                   THEN $$ALTER SYSTEM SET log_connections = ON;$$
        WHEN name = 'log_disconnections'                THEN $$ALTER SYSTEM SET log_disconnections = ON;$$
        WHEN name = 'log_duration'                      THEN $$ALTER SYSTEM RESET log_duration;$$
        WHEN name = 'log_error_verbosity'               THEN $$ALTER SYSTEM RESET log_error_verbosity;$$
        WHEN name = 'log_hostname'                      THEN $$ALTER SYSTEM RESET log_hostname;$$
        WHEN name = 'log_line_prefix'                   THEN $$ALTER SYSTEM SET log_line_prefix = '%t p[%p] l[%l]%q, user=%u, db=%d, client=%h, app=%a, queryid=%Q > ';$$
        WHEN name = 'log_lock_waits'                    THEN $$ALTER SYSTEM SET log_lock_waits = ON;$$
        WHEN name = 'log_lock_failures'                 THEN $$ALTER SYSTEM SET log_lock_failures = ON;$$
        WHEN name = 'log_recovery_conflict_waits'       THEN $$ALTER SYSTEM SET log_recovery_conflict_waits = ON;$$
        WHEN name = 'log_parameter_max_length'          THEN $$ALTER SYSTEM RESET log_parameter_max_length;$$
        WHEN name = 'log_parameter_max_length_on_error' THEN $$ALTER SYSTEM RESET log_parameter_max_length_on_error;$$
        WHEN name = 'log_statement'                     THEN $$ALTER SYSTEM SET log_statement = 'DDL';$$
        WHEN name = 'log_replication_commands'          THEN $$ALTER SYSTEM SET log_replication_commands = ON;$$
        WHEN name = 'log_temp_files'                    THEN $$ALTER SYSTEM SET log_temp_files = 0;$$
        WHEN name = 'log_timezone'                      THEN $$ALTER SYSTEM SET log_timezone = '$$ || current_setting('TimeZone') || $$';$$
        WHEN name = 'lc_messages'                       THEN $$ALTER SYSTEM SET lc_messages = 'C';$$
        WHEN name = 'track_activities'                  THEN $$ALTER SYSTEM RESET track_activities;$$
        WHEN name = 'track_activity_query_size'         THEN $$ALTER SYSTEM SET track_activity_query_size = 8192;$$
        WHEN name = 'track_counts'                      THEN $$ALTER SYSTEM RESET track_counts;$$
        WHEN name = 'track_io_timing'                   THEN $$ALTER SYSTEM SET track_io_timing = ON;$$
        WHEN name = 'track_wal_io_timing'               THEN $$ALTER SYSTEM SET track_wal_io_timing = ON;$$
        WHEN name = 'track_cost_delay_timing'           THEN $$ALTER SYSTEM SET track_cost_delay_timing = ON;$$
        WHEN name = 'track_functions'                   THEN $$ALTER SYSTEM SET track_functions = ALL;$$
        WHEN name = 'stats_fetch_consistency'           THEN $$ALTER SYSTEM RESET stats_fetch_consistency;$$
        WHEN name = 'compute_query_id'                  THEN $$ALTER SYSTEM RESET compute_query_id;$$
        WHEN name = 'log_statement_stats'               THEN $$ALTER SYSTEM RESET log_statement_stats;$$
        WHEN name = 'log_parser_stats'                  THEN $$ALTER SYSTEM RESET log_parser_stats;$$
        WHEN name = 'log_planner_stats'                 THEN $$ALTER SYSTEM RESET log_planner_stats;$$
        WHEN name = 'log_executor_stats'                THEN $$ALTER SYSTEM RESET log_executor_stats;$$
        WHEN name = 'shared_preload_libraries'          THEN $$ALTER SYSTEM SET shared_preload_libraries = $$ || 
	    CASE WHEN setting = $$$$ THEN $$pg_stat_statements;$$ ELSE setting || $$, pg_stat_statements;$$ END
        WHEN name = 'pg_stat_statements.track'          THEN $$ALTER SYSTEM SET pg_stat_statements.track = 'all';$$
        WHEN name = 'pg_stat_statements.track_utility'  THEN $$ALTER SYSTEM SET pg_stat_statements.track_utility = ON;$$
        WHEN name = 'pg_stat_statements.track_planning' THEN $$ALTER SYSTEM SET pg_stat_statements.track_planning = ON;$$
        WHEN name = 'pg_stat_statements.save'           THEN $$ALTER SYSTEM RESET pg_stat_statements.save;$$
    END || ' -- ' AS "Command",
    setting       AS "Current value",
    source || CASE source WHEN 'configuration file' THEN ' ' || sourcefile || ' +' || sourceline AS "Source"
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
                OR  (setting NOT LIKE '%%t%' AND setting NOT LIKE '%%m%')
                OR   setting NOT LIKE '%%Q%')) OR
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
