\ir variables.sql

\if :svp_pg_93
  \ir object_privileges_list_93+.sql
\elif :svp_pg_90
  \ir object_privileges_list_90+.sql
\elif :svp_pg_82
  \ir object_privileges_list_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
