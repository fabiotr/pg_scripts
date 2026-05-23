\ir variables.sql

\if :svp_pg_12
  \ir index_functions_12up.sql
\elif :svp_pg_82
  \ir index_functions_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
