\ir variables.sql

\if :svp_pg_91
  \ir reindex_on_new_glibc_91+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
