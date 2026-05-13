\ir variables.sql

\if :svp_pg_11
  \ir function_aggregates_11+.sql
\elif :svp_pg_84
  \ir function_aggregates_84+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
