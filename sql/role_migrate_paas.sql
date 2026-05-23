\ir variables.sql

\x on
\if :svp_pg_84
  \ir role_migrate_paas_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
