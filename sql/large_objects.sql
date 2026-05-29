\ir variables.sql

\x on
\if :svp_pg_12
  \ir large_objects_12up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
