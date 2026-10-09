\ir variables.sql

\if :svp_pg_12
  \if :svp_largeobject
    \ir large_objects_12up.sql
  \else
    \qecho - Needs superuser (or SELECT on pg_largeobject)
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
