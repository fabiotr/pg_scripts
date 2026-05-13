\ir variables.sql

\if :svp_pg_10
  \i connections_by_app_name_10+.sql
\elif :svp_pg_92
  \i connections_by_app_name_92+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
