\ir variables.sql

-- Check if pg_stat_statements is installed
\if :svp_pg_84
  \if :svp_lib
    \if :svp_track_disabled
      \qecho '# WARNING'
      \qecho 'pg_stat_statements.track is disabled'
      \qecho
      \set svp_run_ok FALSE
    \else
      \if :svp_pg_91
        \if :svp_not_ext
          \if :svp_not_standby
            CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
            \set svp_run_ok TRUE
          \else
            \qecho '# WARNING'
            \qecho 'pg_stat_statemens is not installed in this database and can not be installed on Standby cluster'
            \qecho 'Please install it on Master cluster first'
            \qecho
            \set svp_run_ok FALSE
          \endif
        \else
          \set svp_run_ok TRUE
        \endif
      \else
        \if :svp_not_statements
          \qecho '# WARNING'
          \qecho 'pg_stat_staements is not installed in this database'
          \qecho 'Please install it first'
          \qecho
          \set svp_run_ok FALSE
        \else
          \set svp_run_ok TRUE
        \endif
      \endif
    \endif
  \else 
    \qecho '# WARINING'
    \qecho 'pg_stat_statements is not installed on this cluster'
    \qecho 'Please configure shared_preload_libraries and reboot cluster first'
    \qecho
    \set svp_run_ok FALSE
  \endif
\else
  \qecho '# WARNING'
  \qecho '- pg_stat_statements is not supported on version ' :svp_server_version
  \qecho
  \set svp_run_ok FALSE
\endif

\if :svp_run_ok
  \x off
  \qecho
  \qecho '## Statements'
  \qecho

  \qecho '### Statements total'
  \qecho

  \if :svp_pg_92
    \pset xheader_width 1
  \endif

  \x on
  \if :svp_pg_17
    \ir statements_total_17up.sql
  \elif :svp_pg_14
    \ir statements_total_14up.sql
  \else
    \qecho '- pg_stat_statements TOTAL is not supported on version' :svp_server_version
  \endif
  \x off

  \if :svp_pg_92
    \pset xheader_width full
  \endif

  \qecho
  \qecho '### Statements summary by total time'
  \qecho

  \if   :svp_pg_18
    \ir statements_summary_18up.sql
  \elif :svp_pg_17
    \ir statements_summary_17up.sql
  \elif :svp_pg_14
    \ir statements_summary_14up.sql
  \else
    \qecho '- pg_stat_statements SUMMARY is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by execution time'
  \qecho

  \if   :svp_pg_17
    \ir statements_time_17up.sql
  \elif :svp_pg_14
    \ir statements_time_14up.sql
  \elif :svp_pg_13
    \ir statements_time_13up.sql
  \elif :svp_pg_95
    \ir statements_time_95up.sql
  \elif :svp_pg_94
    \ir statements_time_94up.sql
  \elif :svp_pg_84
    \ir statements_time_84up.sql
  \else
    \qecho '- pg_stat_statements TOTAL is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by plan time'
  \qecho

  \if :svp_plan
    \if :svp_pg_17
      \ir statements_plan_17up.sql
    \elif :svp_pg_14
      \ir statements_plan_14up.sql
    \else
      \qecho '- pg_stat_statements PLAN is not supported on version' :svp_server_version
    \endif
  \else
    \qecho '- pg_stat_statements.track_planning is not enabled on this cluster'
  \endif 

  \qecho
  \qecho '### Statements by shared I/O'
  \qecho 

  \if :svp_track_io
    \if :svp_pg_17
      \ir statements_shared_17up.sql
    \elif :svp_pg_14
      \ir statements_shared_14up.sql
    \elif :svp_pg_92
      \ir statements_shared_92up.sql
    \else
      \qecho '- pg_stat_statements SHARED I/O is not supported on version' :svp_server_version
    \endif
  \else
    \if :svp_pg_92
      \qecho '- track_io_timing is not enabled on this cluster'
    \else
      \qecho '- track_io_timing is not supported on version' :svp_server_version
    \endif
  \endif

  \qecho
  \qecho '### Statements by local I/O'
  \qecho 

  \if :svp_track_io
    \if :svp_pg_17
      \ir statements_local_17up.sql
    \elif :svp_pg_14
      \ir statements_local_14up.sql
    \elif :svp_pg_92
      \ir statements_local_92up.sql
    \else 
      \qecho '- pg_stat_statements LOCAL I/O is not supported on version' :svp_server_version
    \endif
  \else
    \if :svp_pg_92
      \qecho '- track_io_timing is not enabled on this cluster'
    \else
      \qecho '- track_io_timing is not supported on version' :svp_server_version
    \endif
  \endif

  \if :svp_not_standby
    \if :svp_not_aurora
      \qecho
      \qecho '### Statements by WAL I/O'
      \qecho 

      \if :svp_pg_18
        \ir statements_wal_18up.sql
      \elif :svp_pg_17
        \ir statements_wal_17up.sql
      \elif :svp_pg_14
        \ir statements_wal_14up.sql
      \elif :svp_pg_13
        \ir statements_wal_13up.sql
      \else
        \qecho '- pg_stat_statements WAL I/O is not supported on version' :svp_server_version
      \endif
    \endif
  \endif

    \qecho
    \qecho '### Statements by Jit'
    \qecho
  
  \if :svp_jit
    \if :svp_pg_17
      \ir statements_jit_17up.sql
    \elif :svp_pg_15
      \ir statements_jit_15up.sql
    \else 
      \qecho '- pg_stat_statements JIT is not supported on version' :svp_server_version
    \endif
  \else 
    \if :svp_pg_11
      \qecho '- JIT in not enabled on this cluster'
    \else
      \qecho '- JIT is not supported on version' :svp_server_version
    \endif
  \endif

  \qecho
  \qecho '### Statements by calls'
  \qecho

  \if :svp_pg_14
    \ir statements_calls_14up.sql
  \elif :svp_pg_13
    \ir statements_calls_13up.sql
  \elif :svp_pg_95
    \ir statements_calls_95up.sql
  \elif :svp_pg_94
    \ir statements_calls_94up.sql
  \elif :svp_pg_84
    \ir statements_calls_84up.sql
  \else
    \qecho '- pg_stat_statements CALLS is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by rows'
  \qecho

  \if :svp_pg_14
    \ir statements_rows_14up.sql
  \elif :svp_pg_13
    \ir statements_rows_13up.sql
  \elif :svp_pg_95
    \ir statements_rows_95up.sql
  \elif :svp_pg_94
    \ir statements_rows_94up.sql
  \elif :svp_pg_84
    \ir statements_rows_84up.sql
  \else
    \qecho '- pg_stat_statements ROWS is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by rows per call'
  \qecho

  \if :svp_pg_14
    \ir statements_rows_call_14up.sql
  \elif :svp_pg_13
    \ir statements_rows_call_13up.sql
  \elif :svp_pg_95
    \ir statements_rows_call_95up.sql
  \elif :svp_pg_94
    \ir statements_rows_call_94up.sql
  \elif :svp_pg_84
    \ir statements_rows_call_84up.sql
  \else
    \qecho '- pg_stat_statements CALLS is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by temp files'
  \qecho

  \if   :svp_pg_17
    \ir statements_temp_17up.sql
  \elif :svp_pg_14
    \ir statements_temp_14up.sql
  \elif :svp_pg_13 
    \ir statements_temp_13up.sql
  \elif :svp_pg_95
    \ir statements_temp_95up.sql
  \elif :svp_pg_94
    \ir statements_temp_94up.sql
  \elif :svp_pg_92
    \ir statements_temp_92up.sql
  \elif :svp_pg_90
    \ir statements_temp_90up.sql
  \else
    \qecho '- pg_stat_statements TEMP FILES is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Top5 statements by total time with full SQL'
  \qecho

  \if :svp_pg_92
    \pset xheader_width 1
  \endif

  \x on
  \if :svp_pg_17
    \ir statements_top5_17up.sql
  \elif :svp_pg_13 
    \ir statements_top5_13up.sql
  \elif :svp_pg_95
    \ir statements_top5_95up.sql
  \elif :svp_pg_94
    \ir statements_top5_94up.sql
  \elif :svp_pg_84
    \ir statements_top5_84up.sql
  \else
    \qecho '- pg_stat_statements TOP5 is not supported on version' :svp_server_version
  \endif
  \qecho
\else
  \qecho 'Execution of pg_stat_statements scripts was aborted'
  \qecho
\endif

\x off
\if :svp_pg_92
  \pset xheader_width full
\endif 

\timing on
\set QUIET off

