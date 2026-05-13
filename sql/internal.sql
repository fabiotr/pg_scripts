\ir variables.sql

\x on
\if :svp_pg_18
  \ir internal_18+.sql
\elif :svp_pg_15
  \ir internal_15+.sql
\elif :svp_pg_14
  \ir internal_14+.sql
\elif :svp_pg_13
  \ir internal_13+.sql
\elif :svp_pg_93
  \ir internal_93+.sql
\elif :svp_pg_90
  \ir internal_90+.sql
\elif :svp_pg_84
  \ir internal_84+.sql
\elif :svp_pg_82
  \ir internal_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x auto
\timing on
\set QUIET off
