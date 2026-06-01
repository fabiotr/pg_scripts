\ir variables.sql

\if :svp_pg_10
  \ir subscription_table_stats_10up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
