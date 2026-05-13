\ir variables.sql

\if :svp_pg_13
  \ir replication_slots_13+.sql
\elif :svp_pg_12
  \ir replication_slots_12+.sql
\elif :svp_pg_95
  \ir replication_slots_95+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
