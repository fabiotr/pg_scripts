\ir variables.sql

\if :svp_pg_10
  \ir pg_hba_10up.sql 
\else
  \qecho - Not supported on version :svp_server_version (BUT YOU SHOULD COLLECT THIS INFORMATION ON pg_hba.conf )
\endif
\timing on
\set QUIET off
