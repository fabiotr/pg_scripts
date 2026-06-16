\ir variables.sql

\if :svp_pg_18
  \ir statements_cluster_total_by_database_18up.sql
\elif :svp_pg_17
  \ir statements_cluster_total_by_database_17up.sql
\elif :svp_pg_13
  \ir statements_cluster_total_by_database_14up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
