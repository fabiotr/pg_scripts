\ir variables.sql

\if :svp_pg_17
  \ir stats_last_reset_17up.sql
\elif :svp_pg_16
  \ir stats_last_reset_16up.sql
\elif :svp_pg_15
  \ir stats_last_reset_15up.sql
\elif :svp_pg_14
  \ir stats_last_reset_14up.sql
\elif :svp_pg_13
  \ir stats_last_reset_13up.sql
\elif :svp_pg_94
  \ir stats_last_reset_94up.sql
\elif :svp_pg_91
  \ir stats_last_reset_91up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif

\timing on
\set QUIET off
