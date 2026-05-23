\ir variables.sql

\if :svp_pg_17
  \ir vacuum_blocker_17up.sql
\elif :svp_pg_13
  \ir vacuum_blocker_13up.sql
\elif :svp_pg_12
  \ir vacuum_blocker_12up.sql
\elif :svp_pg_10
  \ir vacuum_blocker_10up.sql
\elif :svp_pg_94
  \ir vacuum_blocker_94up.sql
\else
  \qecho - vacuum_wraparound_table is not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
