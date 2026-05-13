\ir variables.sql

\if :svp_pg_91
  \ir revoke_from_pg_catalog_functions_91+.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
