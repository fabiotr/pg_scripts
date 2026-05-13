\ir variables.sql

\if :svp_pg_10
  \i connections_by_user_10+.sql
\elif :svp_pg_92
  \i connections_by_user_92+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
