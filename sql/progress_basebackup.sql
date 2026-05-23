\ir variables.sql

\if :svp_pg_13
  \ir progress_basebackup_13up.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
