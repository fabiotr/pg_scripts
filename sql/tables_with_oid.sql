\ir variables.sql

\if :svp_under_pg_12
  \ir tables_with_oid_11-.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on 
\set QUIET off
