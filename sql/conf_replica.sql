\ir variables.sql

\if :svp_pg_84
  \ir conf_replica_84+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
