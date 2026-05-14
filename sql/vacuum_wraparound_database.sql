\ir variables.sql

\if :svp_pg_14
  \ir vacuum_wraparound_database_14+.sql 
\elif :svp_pg_93
  \ir vacuum_wraparound_database_93+.sql
\elif :svp_pg_82
  \ir vacuum_wraparound_database_82+.sql
\else
  \qecho - vacuum_wraparound_table is not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
