\ir variables.sql

\if :svp_pg_90
  -- The call to the extension's own pg_stat_statements_reset(), schema qualified and with
  -- explicit arguments, so the check and the call use the same function wherever the
  -- extension is installed and no other function with that name can make it ambiguous.
  -- 0 means "all" for userid/dbid/queryid, and minmax_only (1.11+) is false. A signature
  -- with other argument types isn't known here: then the check fails and nothing is reset.
  -- 9.0 has no extensions: plain call there.
  \if :svp_pg_91
    SELECT
      coalesce(max(c.call), 'pg_stat_statements_reset()') AS pgss_reset_call,
      coalesce(max(c.oid::text), '0') AS pgss_reset_oid
    FROM (
      SELECT
        p.oid,
        quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' || coalesce((
          SELECT string_agg(CASE format_type(p.proargtypes[i], NULL)
                              WHEN 'oid'     THEN '0::oid'
                              WHEN 'bigint'  THEN '0::bigint'
                              WHEN 'boolean' THEN 'false'
                            END, ', ' ORDER BY i)
          FROM generate_series(0, p.pronargs - 1) AS i), '') || ')' AS call,
        (SELECT count(1) FROM generate_series(0, p.pronargs - 1) AS i
         WHERE format_type(p.proargtypes[i], NULL) NOT IN ('oid', 'bigint', 'boolean')) AS unknown_args
      FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        JOIN pg_depend d    ON d.classid = 'pg_proc'::regclass AND d.objid = p.oid AND d.deptype = 'e'
        JOIN pg_extension e ON e.oid = d.refobjid AND e.extname = 'pg_stat_statements'
      WHERE p.proname = 'pg_stat_statements_reset'
    ) AS c
    WHERE c.unknown_args = 0
    \gset svp_
  \else
    \set svp_pgss_reset_call 'pg_stat_statements_reset()'
    \set svp_pgss_reset_oid 0
  \endif

  -- Check every reset function this version calls before resetting anything, so
  -- a missing privilege can't leave the stats half reset. A core function this version
  -- doesn't have (to_regprocedure() is NULL) or that the branches below skip counts as OK.
  \if :svp_pg_10
    SELECT
          coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset()'),           'EXECUTE'), TRUE)
      AND coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset_shared(text)'), 'EXECUTE'), TRUE)
      -- 17+ resets the SLRU stats with pg_stat_reset_shared() and doesn't call pg_stat_reset_slru()
      AND (:'svp_pg_17'::boolean OR NOT :'svp_not_gcp'::boolean
           OR coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset_slru(text)'), 'EXECUTE'), TRUE))
      AND (NOT :'svp_not_rds'::boolean OR NOT :'svp_not_gcp'::boolean
           OR coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset_replication_slot(text)'), 'EXECUTE'), TRUE))
      AND (NOT :'svp_not_rds'::boolean
           OR coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_stat_reset_subscription_stats(oid)'), 'EXECUTE'), TRUE))
      AND (NOT :'svp_lib'::boolean OR NOT :'svp_ext'::boolean
           OR (:'svp_pgss_reset_oid'::oid <> 0 AND has_function_privilege(:'svp_pgss_reset_oid'::oid, 'EXECUTE'))) AS reset_ok
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
