\ir variables.sql

\if :svp_pg_95
  \if :svp_replication_origin_status
    \ir replication_origin_95up.sql
  \else
    \qecho - Needs superuser (or SELECT on pg_replication_origin_status and EXECUTE on pg_show_replication_origin_status())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
