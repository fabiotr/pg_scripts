\ir variables.sql

\x on
\if :svp_pg_17
  \ir bgwriter_17+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
