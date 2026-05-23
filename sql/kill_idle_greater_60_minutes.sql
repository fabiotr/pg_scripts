\ir variables.sql

\if :svp_pg_14
  \ir kill_idle_greater_60_minutes_14up.sql
\elif :svp_pg_10
  \ir kill_idle_greater_60_minutes_10up.sql
\elif :svp_pg_92
  \ir kill_idle_greater_60_minutes_92up.sql
\elif :svp_pg_90
  \ir kill_idle_greater_60_minutes_90up.sql
\elif :svp_pg_84
  \ir kill_idle_greater_60_minutes_84up.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
