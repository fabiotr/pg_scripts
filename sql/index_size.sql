\ir variables.sql

\if :svp_pg_91
  \ir index_size_91up.sql
\elif :svp_pg_83
  \ir index_size_83up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
