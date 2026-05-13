\ir variables.sql

\if :svp_pg_95
  \ir trigger_events_95+.sql
\elif :svp_pg_93
  \ir trigger_events_93+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
