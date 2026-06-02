\ir variables.sql

\if :svp_pg_83
  \ir data_types_83up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
