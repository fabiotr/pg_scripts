\set QUIET on
\timing off

SELECT
        ,current_setting('server_version_num')::int < 120000  AS pg_12
        ,current_setting('server_version') AS server_version
\gset svp_


\if :svp_pg_12
  \ir tables_with_oid_11-.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on 
\set QUIET off
