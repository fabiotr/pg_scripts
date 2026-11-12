\ir variables.sql

\if :svp_pg_18
  \if :svp_gin_index_check
    \ir index_check_gin_integrity_18up.sql
  \else
    \qecho - Needs the amcheck extension (and EXECUTE on gin_index_check())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
