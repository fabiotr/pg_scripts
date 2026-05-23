\ir variables.sql

\if :svp_pg_18
  \ir subscription_stats_18up.sql
\elif :svp_pg_16
  \ir subscription_stats_16up.sql
\elif :svp_pg_15
  \ir subscription_stats_15up.sql
\elif :svp_pg_14
  \ir subscription_stats_14up.sql
\elif :svp_pg_10
  \ir subscription_stats_10up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
