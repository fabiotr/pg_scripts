\ir variables.sql

\x on
\if :svp_pg_18
  \ir wal_18+.sql
\elif :svp_pg_14
  \ir wal_14+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
