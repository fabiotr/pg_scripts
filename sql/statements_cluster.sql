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
  \if :svp_pg_14
    \qecho '### Statements total on cluster'
    \qecho
    \ir statements_cluster_total.sql
    \qecho

    \qecho '### Statements total grouped by database'
    \qecho
    \ir statements_cluster_total_by_database.sql
    \qecho

    \qecho '### Statements summary from cluster by time'
    \qecho
    \ir statements_cluster_summary.sql
    \qecho
  \else
    \qecho '### Statements from cluster by time'
    \qecho
    \ir statements_cluster_time.sql
    \qecho
  \endif

  \qecho '### Statements from cluster by temp'
  \qecho
  \ir statements_cluster_temp.sql
  \qecho

\else
  \qecho 'Execution of pg_stat_statements scripts was aborted'
  \qecho
\endif

\timing on
\set QUIET off
