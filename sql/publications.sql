\ir variables.sql

\x on
\if :svp_pg_13
  \ir publications_13up.sql
\elif :svp_pg_11
  \ir publications_11up.sql
\elif :svp_pg_10
  \ir publications_10up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off

