\ir variables.sql

\if :svp_pg_91
  \ir tables_without_index_91+.sql
\elif :svp_pg_82
  \ir tables_without_index_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
