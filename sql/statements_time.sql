\ir variables.sql

\if :svp_pg_17
  \ir statements_time_17+.sql
\elif :svp_pg_14
  \ir statements_time_14+.sql
\elif :svp_pg_13
  \ir statements_time_13+.sql
\elif :svp_pg_95
  \ir statements_time_95+.sql
\elif :svp_pg_94
  \ir statements_time_94+.sql
\elif :svp_pg_84
  \ir statements_time_84+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
