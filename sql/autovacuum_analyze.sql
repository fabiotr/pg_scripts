\ir variables.sql

\if :svp_pg_82
  \ir autovacuum_analyze_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
