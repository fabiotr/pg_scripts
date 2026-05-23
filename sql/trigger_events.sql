\ir variables.sql

\if :svp_pg_95
  \ir trigger_events_95up.sql
\elif :svp_pg_93
  \ir trigger_events_93up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
