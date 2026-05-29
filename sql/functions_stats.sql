\ir variables.sql

\if :svp_pg_91
  \ir functions_stats_91up.sql
\elif :svp_pg_84
  \ir functions_stats_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
