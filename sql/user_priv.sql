\ir variables.sql

\x off
\if :svp_pg_91
  \ir user_priv_91up.sql 
\elif :svp_pg_82
  \ir user_priv_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif

\x auto
\timing on
\set QUIET off
