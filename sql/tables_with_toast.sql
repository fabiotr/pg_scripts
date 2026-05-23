\ir variables.sql

\if :svp_pg_95
  \ir tables_with_toast_95up.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
