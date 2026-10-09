\ir variables.sql

\if :svp_pg_90
  -- Check every reset function this version calls before resetting anything, so
  -- a missing privilege can't leave the stats half reset. A function this version
  -- doesn't have (to_regprocedure() is NULL) or that the branches below skip counts as OK.
  \if :svp_pg_10
    SELECT
          coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset()'),           'EXECUTE'), TRUE)
      AND coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset_shared(text)'), 'EXECUTE'), TRUE)
      AND (NOT :'svp_not_gcp'::boolean
           OR coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset_slru(text)'), 'EXECUTE'), TRUE))
      AND (NOT :'svp_not_rds'::boolean OR NOT :'svp_not_gcp'::boolean
           OR coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset_replication_slot(text)'), 'EXECUTE'), TRUE))
      AND (NOT :'svp_not_rds'::boolean
           OR coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset_subscription_stats(oid)'), 'EXECUTE'), TRUE))
      AND (NOT :'svp_lib'::boolean OR NOT :'svp_ext'::boolean
           OR coalesce((SELECT bool_and(has_function_privilege(oid, 'EXECUTE')) FROM pg_proc
                        WHERE proname = 'pg_stat_statements_reset' AND pg_function_is_visible(oid)), TRUE)) AS reset_ok
    \gset svp_
  \else
    -- before 10 the reset functions check for superuser in their own code
    \set svp_reset_ok :svp_rol_super
  \endif

  \if :svp_reset_ok
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
  \else
    \qecho - Needs superuser (or EXECUTE on every pg_stat_reset*() function and pg_stat_statements_reset()): nothing was reset
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif

\ir stats_last_reset.sql

\timing on
\set QUIET off
