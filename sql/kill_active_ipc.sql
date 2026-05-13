\ir variables.sql

\if :svp_pg_14
  \ir kill_active_ipc_14+.sql
\elif :svp_pg_10
  \ir kill_active_ipc_10+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
