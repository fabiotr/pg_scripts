\ir variables.sql

\x on
\if :svp_pg_18
  \ir database_stats_18+.sql
\elif :svp_pg_14
  \ir database_stats_14+.sql
\elif :svp_pg_12
  \ir database_stats_12+.sql
\elif :svp_pg_92
  \ir database_stats_92+.sql
\elif :svp_pg_91
  \ir database_stats_91+.sql
\elif :svp_pg_83
  \ir database_stats_83+.sql
\elif :svp_pg_82
  \ir database_stats_82+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
