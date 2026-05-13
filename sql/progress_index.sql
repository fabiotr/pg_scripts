\ir variables.sql

\if :svp_pg_12
  \ir progress_index_12+.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
