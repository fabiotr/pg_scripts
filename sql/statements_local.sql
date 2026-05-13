\ir variables.sql

\if :svp_pg_17
  \ir statements_local_17+.sql
\elif :svp_pg_14
  \ir statements_local_14+.sql
\elif :svp_pg_92
  \ir statements_local_92+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
