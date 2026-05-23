\ir variables.sql

\if :svp_pg_12
  \ir index_big_12up.sql 
\elif :svp_pg_90
  \ir index_big_90up.sql
\elif :svp_pg_82
  \ir index_big_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
