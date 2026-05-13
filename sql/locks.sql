\ir variables.sql

\if :svp_pg_96
  \ir locks_96+.sql
\elif :svp_pg_92
  \ir locks_92+.sql
\elif :svp_pg_83
  \ir locks_83+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
