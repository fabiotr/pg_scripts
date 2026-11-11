\ir variables.sql

\if :svp_pg_96
  \ir autovacuum_vacuum_queue_96up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
