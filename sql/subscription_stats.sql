\ir variables.sql

\if :svp_pg_18
  \ir subscription_stats_18+.sql
\elif :svp_pg_16
  \ir subscription_stats_16+.sql
\elif :svp_pg_15
  \ir subscription_stats_15+.sql
\elif :svp_pg_14
  \ir subscription_stats_14+.sql
\elif :svp_pg_10
  \ir subscription_stats_10+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
