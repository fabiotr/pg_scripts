\ir variables.sql

\if :svp_pg_93
  \ir object_privileges_list_93up.sql
\elif :svp_pg_90
  \ir object_privileges_list_90up.sql
\elif :svp_pg_82
  \ir object_privileges_list_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
