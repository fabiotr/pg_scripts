\ir variables.sql

\if :svp_pg_10
  \i connections_by_database_10up.sql
\elif :svp_pg_92
  \i connections_by_database_92up.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
