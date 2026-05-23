\ir variables.sql

\if :svp_pg_18
  \ir statements_wal_18up.sql
\elif :svp_pg_17
  \ir statements_wal_17up.sql
\elif :svp_pg_14
  \ir statements_wal_14up.sql
\elif :svp_pg_13
  \ir statements_wal_13up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
