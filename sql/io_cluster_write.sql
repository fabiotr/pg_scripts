\ir variables.sql

\if :svp_pg_18
  \ir io_cluster_write_18up.sql
\elif :svp_pg_16
  \ir io_cluster_write_16up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
