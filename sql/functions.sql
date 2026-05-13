\ir variables.sql

\if :svp_pg_91
  \ir functions_91+.sql
\elif :svp_pg_84
  \ir functions_84+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
