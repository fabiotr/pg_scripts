\ir variables.sql

\if :svp_pg_84
  \ir autovacuum_analyze_adjust_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
