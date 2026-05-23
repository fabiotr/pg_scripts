\ir variables.sql

\if :svp_pg_14
  \ir vacuum_wraparound_table_14up.sql 
\elif :svp_pg_93
  \ir vacuum_wraparound_table_93up.sql
\else
  \qecho - vacuum_wraparound_table is not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
