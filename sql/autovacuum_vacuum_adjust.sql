\ir variables.sql

\if :svp_pg_90
  \ir autovacuum_vacuum_adjust_90+.sql 
\elif :svp_pg_84
  \ir autovacuum_vacuum_adjust_84+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
