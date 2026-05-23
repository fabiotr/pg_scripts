\ir variables.sql

\if :svp_pg_90
  \ir user_options_90up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
