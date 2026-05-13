\ir variables.sql

\if :svp_pg_17
  \ir statements_jit_17+.sql
\elif :svp_pg_15
  \ir statements_jit_15+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
