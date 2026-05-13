\ir variables.sql

\if :svp_pg_10
  \ir index_stat_hash_10+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
