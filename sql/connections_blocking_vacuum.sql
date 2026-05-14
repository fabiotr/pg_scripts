\ir variables.sql

\if :svp_pg_13
  \ir connections_blocking_vacuum_13+.sql
\elif :svp_pg_10
  \ir connections_blocking_vacuum_10+.sql
\elif :svp_pg_96
  \ir connections_blocking_vacuum_96+.sql
\elif :svp_pg_94
  \ir connections_blocking_vacuum_94+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
