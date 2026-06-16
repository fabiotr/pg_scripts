\ir variables.sql

\if :svp_pg_14
  \ir replication_slots_logical_14up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
