\ir variables.sql

\x on
\if :svp_pg_10
  \if :svp_ls_waldir
    \ir ls_wal_10up.sql
  \else
    \qecho - Needs pg_monitor (or EXECUTE on pg_ls_waldir())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
