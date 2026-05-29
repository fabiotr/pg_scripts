\ir variables.sql

\x on
\if :svp_pg_96
  \ir access_method_96up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
