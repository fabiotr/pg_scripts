\ir variables.sql

\x on
\if :svp_pg_18
  \ir checkpoints_18up.sql
\elif :svp_pg_17
  \ir checkpoints_17up.sql
\elif :svp_pg_91
  \ir checkpoints_91up.sql
\elif :svp_pg_83
  \ir checkpoints_83up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
