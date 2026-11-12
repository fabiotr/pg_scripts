\ir variables.sql

\if :svp_pg_15
  \ir publication_tables_15up.sql
\elif :svp_pg_12
  \ir publication_tables_12up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
