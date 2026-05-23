\ir variables.sql

\if :svp_pg_84
  \ir conf_others_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
