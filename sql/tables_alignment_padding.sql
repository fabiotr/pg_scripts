\ir variables.sql

\if :svp_pg_94
  \ir tables_alignment_padding_94up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
