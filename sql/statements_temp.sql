\ir variables.sql

\if :svp_pg_17
  \ir statements_temp_17+.sql
\elif :svp_pg_14
  \ir statements_temp_14+.sql
\elif :svp_pg_13
  \ir statements_temp_13+.sql
\elif :svp_pg_95
  \ir statements_temp_95+.sql
\elif :svp_pg_94
  \ir statements_temp_94+.sql
\elif :svp_pg_92
  \ir statements_temp_92+.sql
\elif :svp_pg_90
  \ir statements_temp_90+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
