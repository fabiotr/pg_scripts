\ir variables.sql

\if :svp_pg_14
  \ir connections_running_detail_14up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
