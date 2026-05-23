\ir variables.sql

\if :svp_pg_93
  \ir tablespaces_93up.sql
\elif :svp_pg_92
  \ir tablespaces_92up.sql
\elif :svp_pg_90
  \ir tablespaces_90up.sql
\elif :svp_pg_82
  \ir tablespaces_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
