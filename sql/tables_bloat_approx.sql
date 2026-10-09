\ir variables.sql

--\timing on
\if :svp_pg_95
  \if :svp_pgstattuple_approx
    \ir tables_bloat_approx_95up.sql
  \else
    \qecho - Needs the pgstattuple extension and pg_stat_scan_tables or pg_monitor (or EXECUTE on pgstattuple_approx())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\set QUIET off
