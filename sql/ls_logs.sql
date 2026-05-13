\ir variables.sql


\x on
\if :svp_pg_10
  \ir ls_logs_10+.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
