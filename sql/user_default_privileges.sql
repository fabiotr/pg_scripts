\ir variables.sql

\if :svp_pg_95
  \i user_default_privileges_95up.sql
\elif :svp_pg_90
  \i user_default_privileges_90up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
