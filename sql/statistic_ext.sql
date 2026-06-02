\ir variables.sql

\if :svp_pg_12
  \ir statistic_ext_12up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
