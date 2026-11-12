\ir variables.sql

\if :svp_pg_10
  \if :svp_subscription_catalog
    \ir subscription_table_stats_10up.sql
  \else
    \qecho - Needs superuser (or SELECT on pg_subscription)
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
