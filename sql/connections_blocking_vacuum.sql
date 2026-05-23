\ir variables.sql

\if :svp_pg_13
  \ir connections_blocking_vacuum_13up.sql
\elif :svp_pg_10
  \ir connections_blocking_vacuum_10up.sql
\elif :svp_pg_96
  \ir connections_blocking_vacuum_96up.sql
\elif :svp_pg_94
  \ir connections_blocking_vacuum_94up.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
