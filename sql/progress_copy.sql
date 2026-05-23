\ir variables.sql

\if :svp_pg_17
  \ir progress_copy_17up.sql 
\elif :svp_pg_14
  \ir progress_copy_14up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
