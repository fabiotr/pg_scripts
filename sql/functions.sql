\ir variables.sql

\x on
\if :svp_pg_11
  \ir functions_11up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
