\ir variables.sql

\if :svp_pg_17
  \ir progress_copy_17+.sql 
\elif :svp_pg_14
  \ir progress_copy_14+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
