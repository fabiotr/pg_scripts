\ir variables.sql

--\pset xheader_width 1
\x on
\if   :svp_pg_18 
  \ir statements_total_18+.sql
\elif :svp_pg_17
  \ir statements_total_17+.sql
\elif :svp_pg_14
  \ir statements_total_14+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x auto
--\pset xheader_width full
\timing on
\set QUIET off
