\ir variables.sql

\if :svp_pg_11
  \ir functions_11up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
