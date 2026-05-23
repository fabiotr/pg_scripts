\ir variables.sql

\if :svp_pg_10
  \ir index_stat_btree_reindex_10up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
