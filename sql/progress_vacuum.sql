\ir variables.sql

\if :svp_pg_18
  \ir progress_vacuum_18+.sql
\elif :svp_pg_17
  \ir progress_vacuum_17+.sql
\elif :svp_pg_96
  \ir progress_vacuum_96+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
