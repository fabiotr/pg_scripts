\ir variables.sql

\if :svp_pg_93
  \ir index_stat_gin_93up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
