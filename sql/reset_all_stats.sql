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
  \ir reset_all_stats_17+.sql
\elif :svp_pg_16
  \ir reset_all_stats_16+.sql
\elif :svp_pg_15
  \ir reset_all_stats_15+.sql
\elif :svp_pg_14
  \ir reset_all_stats_14+.sql
\elif :svp_pg_13
  \ir reset_all_stats_13+.sql
\elif :svp_pg_94
  \ir reset_all_stats_94+.sql
\elif :svp_pg_91
  \ir reset_all_stats_91+.sql
\elif :svp_pg_90
  \ir reset_all_stats_90+.sql
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
\timing on
\set QUIET off
