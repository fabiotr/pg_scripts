\ir variables.sql

\if :svp_pg_14
  \ir conf_logs_adjust_14up.sql
\elif :svp_pg_94
  \ir conf_logs_adjust_94up.sql
\elif :svp_pg_90
  \ir conf_logs_adjust_90up.sql
\elif :svp_pg_82
  \ir conf_logs_adjust_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
