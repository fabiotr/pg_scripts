\ir variables.sql

\if :svp_pg_95
  \ir vacuum_wraparound_table_multixact_95+.sql 
\else
  \qecho - vacuum_wraparound_table is not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
