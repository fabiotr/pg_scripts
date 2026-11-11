\ir variables.sql

\x on
\if :svp_pg_95
  \ir role_migrate_paas_95up.sql
\elif :svp_pg_91
  \ir role_migrate_paas_91up.sql
\elif :svp_pg_90
  \ir role_migrate_paas_90up.sql
\elif :svp_pg_84
  \ir role_migrate_paas_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
