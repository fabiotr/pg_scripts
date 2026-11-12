\ir variables.sql

\if :svp_pg_14
  \ir vacuum_wraparound_database_14up.sql 
\elif :svp_pg_95
  \ir vacuum_wraparound_database_95up.sql
\elif :svp_pg_82
  \ir vacuum_wraparound_database_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
