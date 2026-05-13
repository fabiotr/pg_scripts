\ir variables.sql

\if :svp_pg_10
  \i connections_by_wait_event_10+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
