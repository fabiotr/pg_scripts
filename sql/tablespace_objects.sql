\ir variables.sql

\if :svp_pg_94
  \ir tablespace_objects_94+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
