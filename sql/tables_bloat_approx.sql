\ir variables.sql

--\timing on
\if :svp_pg_95
  \ir tables_bloat_approx_95+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\set QUIET off
