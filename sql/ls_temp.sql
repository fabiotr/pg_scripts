\ir variables.sql

\x on
\if :svp_pg_12
  \ir ls_temp_12+.sql 
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
