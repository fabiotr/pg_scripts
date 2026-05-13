\ir variables.sql

\if :svp_pg_18
  \ir statements_group_database_total_18+.sql
\elif :svp_pg_17
  \ir statements_group_database_total_17+.sql
\elif :svp_pg_13
  \ir statements_group_database_total_14+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
