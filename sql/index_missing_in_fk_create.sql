\ir variables.sql

\set QUIET on
\timing off
\if :svp_pg_94
  \ir index_missing_in_fk_create_94up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\set QUIET off
