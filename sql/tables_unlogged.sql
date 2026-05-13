\ir variables.sql

\if :svp_pg_93
  \ir tables_unlogged_93+.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
