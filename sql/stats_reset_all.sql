\ir variables.sql

\pset footer off
SET client_min_messages TO warning ;

\if :svp_lib
  \if :svp_pg_91
    \if :svp_ext
      \if :svp_not_gcp
        SET pg_stat_statements.track TO 'none';
      \endif
    \endif
  \endif
\endif

\qecho
\qecho '*** Resetting all stats ***'
\qecho


\if :svp_pg_17
  \ir stats_reset_all_17up.sql
\elif :svp_pg_16
  \ir stats_reset_all_16up.sql
\elif :svp_pg_15
  \ir stats_reset_all_15up.sql
\elif :svp_pg_14
  \ir stats_reset_all_14up.sql
\elif :svp_pg_13
  \ir stats_reset_all_13up.sql
\elif :svp_pg_94
  \ir stats_reset_all_94up.sql
\elif :svp_pg_91
  \ir stats_reset_all_91up.sql
\elif :svp_pg_90
  \ir stats_reset_all_90up.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif

\if :svp_lib
  \if :svp_pg_91
    \if :svp_ext
      \if :svp_not_gcp
        RESET pg_stat_statements.track;
      \endif
    \endif
  \endif 
\endif

RESET client_min_messages;
\pset footer on

\ir stats_last_reset.sql

\timing on
\set QUIET off
