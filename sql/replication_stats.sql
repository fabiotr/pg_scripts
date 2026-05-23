\ir variables.sql

--\x on
\if :svp_pg_12
  \ir replication_stats_12up.sql
\elif :svp_pg_10
  \ir replication_stats_10up.sql
\elif :svp_pg_95
  \ir replication_stats_95up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
--\x off
\timing on
\set QUIET off
