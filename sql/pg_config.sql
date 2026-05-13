\ir variables.sql

\t on
\if :svp_pg_96
  \ir pg_config_96+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\t off
\timing on
\set QUIET off
