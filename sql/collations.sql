\ir variables.sql

\if :svp_pg_17
  \ir collations_17up.sql
\elif :svp_pg_16
  \ir collations_17up.sql
\elif :svp_pg_15
  \ir collations_15up.sql
\elif :svp_pg_12
  \ir collations_12up.sql
\elif :svp_pg_10
  \ir collations_10up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
