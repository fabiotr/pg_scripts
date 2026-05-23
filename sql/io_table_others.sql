\ir variables.sql

\if :svp_pg_91
  \ir io_table_others_91up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
