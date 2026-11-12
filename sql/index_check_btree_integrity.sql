\ir variables.sql

\if :svp_pg_10
  \if :svp_bt_index_check
    \ir index_check_btree_integrity_10up.sql
  \else
    \qecho - Needs the amcheck extension (and EXECUTE on bt_index_check())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
