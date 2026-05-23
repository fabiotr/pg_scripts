\ir variables.sql

\if :svp_pg_17
  \ir statements_plan_17up.sql
\elif :svp_pg_14
  \ir statements_plan_14up.sql
\else
  \qecho - pg_stat_statements is not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
