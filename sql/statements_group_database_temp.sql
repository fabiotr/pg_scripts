\ir variables.sql

\if :svp_pg_17
  \ir statements_group_database_temp_17up.sql
\elif :svp_pg_14
  \ir statements_group_database_temp_14up.sql
\elif :svp_pg_13
  \ir statements_group_database_temp_13up.sql
\elif :svp_pg_94
  \ir statements_group_database_temp_94up.sql
\elif :svp_pg_92
  \ir statements_group_database_temp_92up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
