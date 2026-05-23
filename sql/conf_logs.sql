\ir variables.sql

\if :svp_pg_18
  \ir conf_logs_18up.sql
\elif :svp_pg_14
  \ir conf_logs_14up.sql
\elif :svp_pg_82
  \ir conf_logs_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
