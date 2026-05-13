\ir variables.sql

\if :svp_pg_91
  \ir io_sequence_91+.sql
\elif :svp_pg_84
  \ir io_sequence_84+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
