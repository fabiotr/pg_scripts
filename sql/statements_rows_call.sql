\ir variables.sql

\if :svp_pg_17
  \ir statements_rows_call_17+.sql
\elif :svp_pg_14
  \ir statements_rows_call_14+.sql
\elif :svp_pg_13
  \ir statements_rows_call_13+.sql
\elif :svp_pg_95
  \ir statements_rows_call_95+.sql
\elif :svp_pg_94
  \ir statements_rows_call_94+.sql
\elif :svp_pg_84
  \ir statements_rows_call_84+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
