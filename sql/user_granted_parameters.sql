\ir variables.sql

\if :svp_pg_15
  \ir user_granted_parameters_15+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
