\ir variables.sql

\if :svp_pg_17
  \ir statements_local_17up.sql
\elif :svp_pg_14
  \ir statements_local_14up.sql
\elif :svp_pg_92
  \ir statements_local_92up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
