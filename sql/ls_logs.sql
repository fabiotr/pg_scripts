\ir variables.sql


\x on
\if :svp_pg_10
  \if :svp_ls_logdir
    \if :svp_logging_collector
      \ir ls_logs_10up.sql
    \else
      \qecho - logging_collector is off: no log files to list
    \endif
  \else
    \qecho - Needs pg_monitor (or EXECUTE on pg_ls_logdir())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
