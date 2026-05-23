\ir variables.sql

\if :svp_pg_92
  \ir autovacuum_vacuum_plus_92up.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
