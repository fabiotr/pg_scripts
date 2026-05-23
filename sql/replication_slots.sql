\ir variables.sql

\if :svp_pg_13
  \ir replication_slots_13up.sql
\elif :svp_pg_12
  \ir replication_slots_12up.sql
\elif :svp_pg_95
  \ir replication_slots_95up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
