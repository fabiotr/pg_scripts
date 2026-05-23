\ir variables.sql

\if :svp_pg_17
  \ir kill_active_wait_events_17up.sql
\elif :svp_pg_14
  \ir kill_active_wait_events_14up.sql
\elif :svp_pg_10
  \ir kill_active_wait_events_10up.sql
\elif :svp_pg_96
  \ir kill_active_wait_events_96up.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
