\ir variables.sql

\if :svp_pg_90
  \ir tables_not_used_90up.sql
\elif :svp_pg_83
  \ir tables_not_used_83up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
