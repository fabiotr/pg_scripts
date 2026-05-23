\ir variables.sql

\if :svp_pg_90
  \ir database_size_90up.sql
\elif :svp_pg_82
  \ir database_size_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
