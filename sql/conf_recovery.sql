\ir variables.sql

\if :svp_pg_12
  \ir conf_recovery_12up.sql
\elif :svp_pg_84
  \if :svp_ls_dir
    \if :svp_read_file_range
      \ir conf_recovery_84up.sql
    \else
      \qecho - Needs superuser (or EXECUTE on pg_ls_dir() and pg_read_file())
    \endif
  \else
    \qecho - Needs superuser (or EXECUTE on pg_ls_dir() and pg_read_file())
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
