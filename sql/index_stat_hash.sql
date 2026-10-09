\ir variables.sql

\if :svp_pg_10
  \if :svp_pgstathashindex
    \ir index_stat_hash_10up.sql
  \else
    \qecho - Needs the pgstattuple extension and pg_stat_scan_tables or pg_monitor (or EXECUTE on pgstathashindex())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
