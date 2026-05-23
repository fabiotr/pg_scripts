\ir variables.sql

\x on
\if :svp_pg_10
  \ir ls_wal_10up.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
