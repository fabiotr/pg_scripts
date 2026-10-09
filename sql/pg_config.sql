\ir variables.sql

\t on
\if :svp_pg_96
  \if :svp_config
    \ir pg_config_96up.sql
  \else
    \qecho - Needs superuser (or SELECT on pg_config and EXECUTE on pg_config())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\t off
\timing on
\set QUIET off
