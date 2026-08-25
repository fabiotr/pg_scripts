\ir variables.sql

\if :svp_pg_91
  \ir tables_constraint_not_valid_91up.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on 
\set QUIET off
