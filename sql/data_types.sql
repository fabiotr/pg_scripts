\ir variables.sql

\x on
\if :svp_pg_83
  \ir data_types_83up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
