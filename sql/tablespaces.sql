\ir variables.sql

\if :svp_pg_93
  \ir tablespaces_93+.sql
\elif :svp_pg_92
  \ir tablespaces_92+.sql
\elif :svp_pg_90
  \ir tablespaces_90+.sql
\elif :svp_pg_82
  \ir tablespaces_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
