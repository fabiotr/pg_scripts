\ir variables.sql

\if :svp_pg_14
  \ir kill_idle_greater_10_minutes_14+.sql
\elif :svp_pg_10
  \ir kill_idle_greater_10_minutes_10+.sql
\elif :svp_pg_92
  \ir kill_idle_greater_10_minutes_92+.sql
\elif :svp_pg_90
  \ir kill_idle_greater_10_minutes_90+.sql
\elif :svp_pg_84
  \ir kill_idle_greater_10_minutes_84+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
