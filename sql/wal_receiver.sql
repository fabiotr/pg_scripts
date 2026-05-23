\ir variables.sql

\x on
\if :svp_pg_11
  \ir wal_receiver_11up.sql
\elif :svp_pg_96
  \ir wal_receiver_96up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
