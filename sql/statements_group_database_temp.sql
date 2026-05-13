\ir variables.sql

\if :svp_pg_17
  \ir statements_group_database_temp_17+.sql
\elif :svp_pg_14
  \ir statements_group_database_temp_14+.sql
\elif :svp_pg_13
  \ir statements_group_database_temp_13+.sql
\elif :svp_pg_94
  \ir statements_group_database_temp_94+.sql
\elif :svp_pg_92
  \ir statements_group_database_temp_92+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
