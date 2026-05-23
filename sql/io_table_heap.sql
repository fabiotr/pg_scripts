\ir variables.sql

\if :svp_pg_91
  \ir io_table_heap_91up.sql
\elif :svp_pg_84
  \ir io_table_heap_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
