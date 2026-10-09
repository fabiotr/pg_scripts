\ir variables.sql

\if :svp_pg_91
  \if :svp_ls_dir
    \if :svp_read_file
      \if :svp_pg_15
        \ir backup_15up.sql
      \elif :svp_pg_93
        \ir backup_93up.sql
      \elif :svp_pg_92
        \ir backup_92up.sql
      \else
        \ir backup_91up.sql
      \endif
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
