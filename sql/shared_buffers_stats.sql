\ir variables.sql

\if :svp_pg_13
  \ir shared_buffers_stats_13+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
