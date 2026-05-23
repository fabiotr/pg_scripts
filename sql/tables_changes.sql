\ir variables.sql

\if :svp_pg_91
  \ir tables_changes_91up.sql
\elif :svp_pg_82
  \ir tables_changes_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
