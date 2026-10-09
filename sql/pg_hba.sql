\ir variables.sql

\if :svp_pg_10
  \if :svp_hba_file_rules
    \ir pg_hba_10up.sql
  \else
    \qecho - Needs superuser (or SELECT on pg_hba_file_rules and EXECUTE on pg_hba_file_rules())
  \endif
\else
  \qecho - Not supported on version :svp_server_version (BUT YOU SHOULD COLLECT THIS INFORMATION ON pg_hba.conf )
\endif
\timing on
\set QUIET off
