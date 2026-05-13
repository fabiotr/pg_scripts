\ir variables.sql

\if :svp_pg_95
  \ir vacuum_full_or_cluster_95+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
