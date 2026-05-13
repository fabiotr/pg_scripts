\ir variables.sql

\if :svp_pg_14
  \ir kill_active_query_time_greater_60_seconds_14+.sql
\elif :svp_pg_10
  \ir kill_active_query_time_greater_60_seconds_10+.sql
\elif :svp_pg_92
  \ir kill_active_query_time_greater_60_seconds_92+.sql
\elif :svp_pg_90
  \ir kill_active_query_time_greater_60_seconds_90+.sql
\elif :svp_pg_84
  \ir kill_active_query_time_greater_60_seconds_84+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
