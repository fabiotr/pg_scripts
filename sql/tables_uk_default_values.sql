\ir variables.sql

\if :svp_pg_90
  \ir tables_uk_default_values_91up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
