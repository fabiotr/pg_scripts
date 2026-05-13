\ir variables.sql

\if :svp_pg_14
  \ir kill_active_bufferpin_14+.sql
\elif :svp_pg_10
  \ir kill_active_bufferpin_10+.sql
\elif :svp_pg_96
  \ir kill_active_bufferpin_96+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
