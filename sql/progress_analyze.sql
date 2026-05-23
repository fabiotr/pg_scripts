\ir variables.sql

\if :svp_pg_13
  \ir progress_analyze_13up.sql 
\elif :svp_pg_18
  \ir progress_analyze_18up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
