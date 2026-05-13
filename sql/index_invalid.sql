\ir variables.sql

\if :svp_pg_12
  \ir index_invalid_12+.sql
\elif :svp_pg_93
  \ir index_invalid_93+.sql
\elif :svp_pg_83
  \ir index_invalid_83+.sql
\elif :svp_pg_82
  \ir index_invalid_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
