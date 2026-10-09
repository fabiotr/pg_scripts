\ir variables.sql

\x on
\if :svp_pg_12
  \if :svp_ls_tmpdir
    \ir ls_temp_12up.sql
  \else
    \qecho - Needs pg_monitor (or EXECUTE on pg_ls_tmpdir())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
