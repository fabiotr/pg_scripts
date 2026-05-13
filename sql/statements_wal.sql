\ir variables.sql

\if :svp_pg_18
  \ir statements_wal_18+.sql
\elif :svp_pg_17
  \ir statements_wal_17+.sql
\elif :svp_pg_14
  \ir statements_wal_14+.sql
\elif :svp_pg_13
  \ir statements_wal_13+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
