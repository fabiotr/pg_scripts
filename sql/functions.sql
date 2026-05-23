\ir variables.sql

\if :svp_pg_91
  \ir functions_91up.sql
\elif :svp_pg_84
  \ir functions_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
