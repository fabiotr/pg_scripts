\ir variables.sql

\if :svp_pg_15
  \ir backup_15+.sql
\elif :svp_pg_93
  \ir backup_93+.sql
\elif :svp_pg_92
  \ir backup_92+.sql
\elif :svp_pg_91
  \ir backup_91+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
