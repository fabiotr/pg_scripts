\ir variables.sql

\if :svp_pg_14
  \ir connections_running_14+.sql
\elif :svp_pg_13
  \ir connections_running_13+.sql
\elif :svp_pg_12
  \ir connections_running_12+.sql
\elif :svp_pg_92
  \ir connections_running_92+.sql
\elif :svp_pg_91
  \ir connections_running_91+.sql
\elif :svp_pg_90
  \ir connections_running_90+.sql
\elif :svp_pg_83
  \ir connections_running_83+.sql
\elif :svp_pg_82
  \ir connections_running_82+.sql
\else
  \qecho - not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
