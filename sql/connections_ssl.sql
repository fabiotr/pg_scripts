\ir variables.sql

\if :svp_pg_12
  \ir connections_ssl_12+.sql
\elif :svp_pg_95
  \ir connections_ssl_95+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
