\ir variables.sql

\x on
\if :svp_pg_18
  \ir statements_group_total_18up.sql
\elif :svp_pg_17
  \ir statements_group_total_17up.sql
\elif :svp_pg_13
  \ir statements_group_total_14up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x auto
\timing on
\set QUIET off
