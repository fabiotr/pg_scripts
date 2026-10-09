\ir variables.sql

\if :svp_pg_83
  \if :svp_pgstatindex
    \if :svp_pg_10
      \ir index_stat_btree_10up.sql
    \elif :svp_pg_94
      \ir index_stat_btree_94up.sql
    \elif :svp_pg_93
      \ir index_stat_btree_93up.sql
    \else
      \ir index_stat_btree_83up.sql
    \endif
  \else
    \qecho - Needs the pgstattuple extension and pg_stat_scan_tables or pg_monitor (or EXECUTE on pgstatindex())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
