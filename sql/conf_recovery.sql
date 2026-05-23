\ir variables.sql

\if :svp_pg_12
  \ir conf_recovery_12up.sql
\elif :svp_pg_84
  \ir conf_recovery_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
