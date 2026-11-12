\ir variables.sql

\if :svp_pg_84
  \ir index_poor_rep_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
