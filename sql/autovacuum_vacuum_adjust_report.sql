\ir variables.sql

\if :svp_pg_90
  \ir autovacuum_vacuum_adjust_report_90up.sql 
\elif :svp_pg_84
  \ir autovacuum_vacuum_adjust_report_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
