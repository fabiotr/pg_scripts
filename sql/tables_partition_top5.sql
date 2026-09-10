\ir variables.sql

\if :svp_pg_12
  \ir tables_partition_top5_12up.sql
\elif :svp_pg_10
  \ir tables_partition_top5_10up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
