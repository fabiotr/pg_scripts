\ir variables.sql

\x on
\if :svp_pg_83
  \ir procedural_languages_83up.sql
\elif :svp_pg_82
  \ir procedural_languages_82up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x off
\timing on
\set QUIET off
