\ir variables.sql

\x on
\if :svp_pg_15
  \ir publication_schemas_15up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
