\ir variables.sql

\if :svp_pg_17
  \ir statements_time_17up.sql
\elif :svp_pg_14
  \ir statements_time_14up.sql
\elif :svp_pg_13
  \ir statements_time_13up.sql
\elif :svp_pg_95
  \ir statements_time_95up.sql
\elif :svp_pg_94
  \ir statements_time_94up.sql
\elif :svp_pg_84
  \ir statements_time_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
