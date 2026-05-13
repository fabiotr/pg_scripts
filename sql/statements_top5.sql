\ir variables.sql

\if :svp_pg_17
  \ir statements_top5_17+.sql
\elif :svp_pg_13
  \ir statements_top5_13+.sql
\elif :svp_pg_96
  \ir statements_top5_96+.sql
\elif :svp_pg_95
  \ir statements_top5_95+.sql
\elif :svp_pg_94
  \ir statements_top5_94+.sql
\elif :svp_pg_84
  \ir statements_top5_84+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
