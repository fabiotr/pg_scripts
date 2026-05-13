\ir variables.sql

\if :svp_pg_94
  \ir schemas_94+.sql
\elif :svp_pg_82
  \ir schemas_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
