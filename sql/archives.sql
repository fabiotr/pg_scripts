\ir variables.sql

\x on
\if :svp_pg_96
  \ir archives_96+.sql
\elif :svp_pg_94
  \ir archives_94+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
