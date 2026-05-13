\ir variables.sql

\if :svp_pg_10
  \ir sequence_setval_10+.sql
\elif :svp_pg_93
  \ir sequence_setval_93+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
