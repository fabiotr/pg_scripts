\ir variables.sql

\if :svp_pg_90
  \ir tables_not_used_90+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
