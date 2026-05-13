\ir variables.sql

\if :svp_pg_90
  \ir trigger_tables_90+.sql
\elif :svp_pg_82
  \ir trigger_tables_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
