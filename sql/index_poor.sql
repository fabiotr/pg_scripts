\ir variables.sql

\if :svp_pg_91
  \ir index_poor_91up.sql
\elif :svp_pg_84
  \ir index_poor_84up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
