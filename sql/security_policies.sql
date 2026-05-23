\ir variables.sql

\if :svp_pg_10
  \ir security_policies_10up.sql
\elif :svp_pg_95
  \ir security_policies_95up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
