\ir variables.sql

\if :svp_pg_16
  \ir user_granted_roles_16+.sql
\elif :svp_pg_95
  \ir user_granted_roles_95+.sql
\elif :svp_pg_82
  \ir user_granted_roles_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
