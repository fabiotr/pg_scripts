\ir variables.sql

\x on
\if :svp_pg_18
  \ir wal_18up.sql
\elif :svp_pg_14
  \ir wal_14up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
