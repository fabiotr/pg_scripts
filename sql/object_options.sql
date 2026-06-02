\ir variables.sql

\if :svp_pg_82
  \ir object_options_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
