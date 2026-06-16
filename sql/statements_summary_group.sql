\ir variables.sql

\if :svp_pg_18
  \ir statements_summary_group_18up.sql
\elif :svp_pg_17
  \ir statements_summary_group_17up.sql
\elif :svp_pg_14
  \ir statements_summary_group_14up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
