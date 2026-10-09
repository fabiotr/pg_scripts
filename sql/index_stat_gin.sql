\ir variables.sql

\if :svp_pg_93
  \if :svp_pgstatginindex
    \ir index_stat_gin_93up.sql
  \else
    \qecho - Needs the pgstattuple extension and pg_stat_scan_tables or pg_monitor (or EXECUTE on pgstatginindex())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
