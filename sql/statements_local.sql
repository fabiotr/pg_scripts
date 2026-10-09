\ir variables.sql

\if :svp_pg_17
  \ir statements_local_17up.sql
\elif :svp_pg_14
  \ir statements_local_14up.sql
\elif :svp_pg_13
  \ir statements_local_13up.sql
\elif :svp_pg_95
  \ir statements_local_95up.sql
\elif :svp_pg_94
  \ir statements_local_94up.sql
\elif :svp_pg_92
  \ir statements_local_92up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
