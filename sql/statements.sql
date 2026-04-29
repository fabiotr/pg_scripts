\set QUIET on
\pset footer off
\timing off
\x off

--Variaveis de configuração */
SELECT 
 	 current_setting('server_version_num')::int >=  80200  AS pg_82
       	,current_setting('server_version_num')::int >=  80300  AS pg_83
       	,current_setting('server_version_num')::int >=  80400  AS pg_84
       	,current_setting('server_version_num')::int >=  90000  AS pg_90
       	,current_setting('server_version_num')::int >=  90100  AS pg_91
       	,current_setting('server_version_num')::int >=  90200  AS pg_92
       	,current_setting('server_version_num')::int >=  90300  AS pg_93
       	,current_setting('server_version_num')::int >=  90400  AS pg_94
       	,current_setting('server_version_num')::int >=  90500  AS pg_95
       	,current_setting('server_version_num')::int >=  90600  AS pg_96
       	,current_setting('server_version_num')::int >= 100000  AS pg_10
       	,current_setting('server_version_num')::int >= 110000  AS pg_11
       	,current_setting('server_version_num')::int >= 120000  AS pg_12
       	,current_setting('server_version_num')::int >= 130000  AS pg_13
       	,current_setting('server_version_num')::int >= 140000  AS pg_14
       	,current_setting('server_version_num')::int >= 150000  AS pg_15
       	,current_setting('server_version_num')::int >= 160000  AS pg_16
	,current_setting('server_version_num')::int >= 170000  AS pg_17
	,current_setting('server_version_num')::int >= 180000  AS pg_18
	,current_setting('server_version')                     AS server_version
	,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'track_io_timing'                   AND setting = 'on') AS track_io
        ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'pg_stat_statements.track_planning' AND setting = 'on') AS plan
        ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'jit'                               AND setting = 'on') AS jit
        ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'aurora_compute_plan_id')                               AS not_aurora
        ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END WHERE current_setting('shared_preload_libraries') LIKE '%pg_stat_statements%')        AS lib
\gset svp_

\if :svp_pg_90
  SELECT NOT pg_is_in_recovery() AS not_standby
  \gset svp_
\else
  \set svp_not_standby FALSE
\endif

-- Check if pg_stat_statements is installed
\if :svp_pg_84
  \if :svp_lib
    \if :svp_pg_91
      SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END AS not_ext FROM pg_extension WHERE extname = 'pg_stat_statements'
      \gset svp_
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
      SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END AS not_statements FROM pg_class WHERE relname = 'pg_stat_statements'
      \gset svp_
      \if svp_not_statements
        \qecho '# WARNING'
        \qecho 'pg_stat_staements is not installed in this database'
        \qecho 'Please install it first'
        \qecho
        \set svp_run_ok FALSE
      \else
        \set svp_run_ok TRUE
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
    \ir statements_total_17+.sql
  \elif :svp_pg_14
    \ir statements_total_14+.sql
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
    \ir statements_summary_18+.sql
  \elif :svp_pg_17
    \ir statements_summary_17+.sql
  \elif :svp_pg_14
    \ir statements_summary_14+.sql
  \else
    \qecho '- pg_stat_statements SUMMARY is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by execution time'
  \qecho

  \if   :svp_pg_17
    \ir statements_time_17+.sql
  \elif :svp_pg_14
    \ir statements_time_14+.sql
  \elif :svp_pg_13
    \ir statements_time_13+.sql
  \elif :svp_pg_95
    \ir statements_time_95+.sql
  \elif :svp_pg_94
    \ir statements_time_94+.sql
  \elif :svp_pg_84
    \ir statements_time_84+.sql
  \else
    \qecho '- pg_stat_statements TOTAL is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by plan time'
  \qecho

  \if :svp_plan
    \if :svp_pg_17
      \ir statements_plan_17+.sql
    \elif :svp_pg_14
      \ir statements_plan_14+.sql
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
      \ir statements_shared_17+.sql
    \elif :svp_pg_14
      \ir statements_shared_14+.sql
    \elif :svp_pg_92
      \ir statements_shared_92+.sql
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
      \ir statements_local_17+.sql
    \elif :svp_pg_14
      \ir statements_local_14+.sql
    \elif :svp_pg_92
      \ir statements_local_92+.sql
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
        \ir statements_wal_18+.sql
      \elif :svp_pg_17
        \ir statements_wal_17+.sql
      \elif :svp_pg_14
        \ir statements_wal_14+.sql
      \elif :svp_pg_13
        \ir statements_wal_13+.sql
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
      \ir statements_jit_17+.sql
    \elif :svp_pg_15
      \ir statements_jit_15+.sql
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
    \ir statements_calls_14+.sql
  \elif :svp_pg_13
    \ir statements_calls_13+.sql
  \elif :svp_pg_95
    \ir statements_calls_95+.sql
  \elif :svp_pg_94
    \ir statements_calls_94+.sql
  \elif :svp_pg_84
    \ir statements_calls_84+.sql
  \else
    \qecho '- pg_stat_statements CALLS is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by rows'
  \qecho

  \if :svp_pg_14
    \ir statements_rows_14+.sql
  \elif :svp_pg_13
    \ir statements_rows_13+.sql
  \elif :svp_pg_95
    \ir statements_rows_95+.sql
  \elif :svp_pg_94
    \ir statements_rows_94+.sql
  \elif :svp_pg_84
    \ir statements_rows_84+.sql
  \else
    \qecho '- pg_stat_statements ROWS is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by rows per call'
  \qecho

  \if :svp_pg_14
    \ir statements_rows_call_14+.sql
  \elif :svp_pg_13
    \ir statements_rows_call_13+.sql
  \elif :svp_pg_95
    \ir statements_rows_call_95+.sql
  \elif :svp_pg_94
    \ir statements_rows_call_94+.sql
  \elif :svp_pg_84
    \ir statements_rows_call_84+.sql
  \else
    \qecho '- pg_stat_statements CALLS is not supported on version' :svp_server_version
  \endif

  \qecho
  \qecho '### Statements by temp files'
  \qecho

  \if   :svp_pg_17
    \ir statements_temp_17+.sql
  \elif :svp_pg_14
    \ir statements_temp_14+.sql
  \elif :svp_pg_13 
    \ir statements_temp_13+.sql
  \elif :svp_pg_95
    \ir statements_temp_95+.sql
  \elif :svp_pg_94
    \ir statements_temp_94+.sql
  \elif :svp_pg_92
    \ir statements_temp_92+.sql
  \elif :svp_pg_90
    \ir statements_temp_90+.sql
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
    \ir statements_top5_17+.sql
  \elif :svp_pg_13 
    \ir statements_top5_13+.sql
  \elif :svp_pg_95
    \ir statements_top5_95+.sql
  \elif :svp_pg_94
    \ir statements_top5_94+.sql
  \elif :svp_pg_84
    \ir statements_top5_84+.sql
  \else
    \qecho '- pg_stat_statements TOP5 is not supported on version' :svp_server_version
  \endif
  \qecho

\else
  \qecho 
  \qecho 'Execution of pg_stat_statements scripts was aborted'
  \qecho
\endif

\x off
\if :svp_pg_92
  \pset xheader_width full
\endif 

\timing on
\set QUIET off

