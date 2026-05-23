\ir variables.sql

\if :svp_pg_10
  \ir connections_tot_10up.sql
\elif :svp_pg_92
  \ir connections_tot_92up.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
