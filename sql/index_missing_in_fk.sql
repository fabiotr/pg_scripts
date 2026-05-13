\ir variables.sql

\if :svp_pg_94
  \ir index_missing_in_fk_94+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
