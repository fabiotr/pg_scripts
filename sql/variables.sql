-- Don't show any annoying messages now
\set QUIET on
\timing off

-- Set configuration variables
SELECT
     current_setting('server_version_num')::int >=  80200  AS pg_82
    ,current_setting('server_version_num')::int >=  80300  AS pg_83
    ,current_setting('server_version_num')::int >=  80400  AS pg_84
    ,current_setting('server_version_num')::int >=  90000  AS pg_90
    ,current_setting('server_version_num')::int >=  90100  AS pg_91
    ,current_setting('server_version_num')::int >=  90200  AS pg_92
    ,current_setting('server_version_num')::int >=  90300  AS pg_93
    ,current_setting('server_version_num')::int >=  90400  AS pg_94
    ,current_setting('server_version_num')::int >=  90500  AS pg_95
    ,current_setting('server_version_num')::int >=  90600  AS pg_96
    ,current_setting('server_version_num')::int >= 100000  AS pg_10
    ,current_setting('server_version_num')::int >= 110000  AS pg_11
    ,current_setting('server_version_num')::int >= 120000  AS pg_12
    ,current_setting('server_version_num')::int >= 130000  AS pg_13
    ,current_setting('server_version_num')::int >= 140000  AS pg_14
    ,current_setting('server_version_num')::int >= 150000  AS pg_15
    ,current_setting('server_version_num')::int >= 160000  AS pg_16
    ,current_setting('server_version_num')::int >= 170000  AS pg_17
    ,current_setting('server_version_num')::int >= 180000  AS pg_18
    ,current_setting('server_version_num')::int <  120000  AS under_pg_12
    ,current_setting('server_version')                     AS server_version
    ,CURRENT_DATE                                          AS date
    ,(SELECT rolsuper FROM pg_roles WHERE rolname = USER)  AS rol_super
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'logging_collector'                 AND setting = 'on')   AS logging_collector
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'track_io_timing'                   AND setting = 'on')   AS track_io
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'pg_stat_statements.track_planning' AND setting = 'on')   AS plan
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'pg_stat_statements.track'          AND setting = 'none') AS track_disabled
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'jit'                               AND setting = 'on')   AS jit
    ,(SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_class    WHERE relname = 'pg_stat_statements')                                  AS not_statements
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'shared_preload_libraries'          AND setting LIKE '%pg_stat_statements%') AS lib
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname IN ('cloudsqladmin', 'rdsadmin'))                        AS not_dbaas
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname = 'cloudsqladmin')                                       AS not_gcp
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname = 'rdsadmin')                                            AS not_rds
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'aurora_compute_plan_id')                                 AS not_aurora
    -- Schema of the pg_stat_statements view, which the scripts use as :svp_pgss.pg_stat_statements so it
    -- works wherever it was installed. Here the view on search_path (contrib SQL before 9.1), public when
    -- there is none; from 9.1 the extension's schema replaces it below.
    ,coalesce((SELECT quote_ident(n.nspname)
               FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
               WHERE c.relname = 'pg_stat_statements' AND c.relkind = 'v' AND pg_table_is_visible(c.oid)), 'public') AS pgss
\gset svp_

--Some variables exists only above specific PG versions
\if :svp_pg_90
  SELECT
    NOT pg_is_in_recovery() AS not_standby,
        pg_is_in_recovery() AS recovery
  \gset svp_
\else
  \set svp_not_standby TRUE
  \set svp_recovery FALSE
\endif

\if :svp_pg_91
  SELECT
     (SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_stat_replication) AS master
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_extension WHERE extname = 'pg_stat_statements') AS ext
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_extension WHERE extname = 'pg_stat_statements') AS not_ext
    ,coalesce((SELECT quote_ident(n.nspname) FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
               WHERE e.extname = 'pg_stat_statements'), :'svp_pgss') AS pgss
  \gset svp_
\else
  \set svp_master FALSE
\endif

\if :svp_pg_94
  \if :svp_master
    SELECT (SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_replication_slots WHERE slot_type = 'logical') AS logical_replication_slot
    \gset svp_
  \endif
  \else
  \set svp_logical_replication_slot FALSE
\endif

\if :svp_pg_10
  SELECT
     (SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_publication) AS publication
    ,(SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_subscription) AS subscription
  \gset svp_
\else
  \set svp_publication FALSE
  \set svp_subscription FALSE
\endif

-- Functions and views that need an extension or more than the default privileges
-- (pg_monitor, pg_stat_scan_tables, pg_read_all_stats or superuser): TRUE when the
-- one the scripts call exists and the user can use it.
\if :svp_pg_94
  -- to_regprocedure() / to_regclass() resolve the exact signature through search_path,
  -- like the call in the script, and give NULL when it doesn't exist
  SELECT
     coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_ls_tmpdir(oid)'),   'EXECUTE'), FALSE) AS ls_tmpdir
    ,coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_ls_waldir()'),      'EXECUTE'), FALSE) AS ls_waldir
    ,coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_ls_logdir()'),      'EXECUTE'), FALSE) AS ls_logdir
    ,coalesce(has_function_privilege(to_regprocedure('pgstatindex(regclass)'),          'EXECUTE'), FALSE) AS pgstatindex
    ,coalesce(has_function_privilege(to_regprocedure('pgstatginindex(regclass)'),       'EXECUTE'), FALSE) AS pgstatginindex
    ,coalesce(has_function_privilege(to_regprocedure('pgstathashindex(regclass)'),      'EXECUTE'), FALSE) AS pgstathashindex
    ,coalesce(has_function_privilege(to_regprocedure('pgstattuple_approx(regclass)'),   'EXECUTE'), FALSE) AS pgstattuple_approx
    ,coalesce(has_table_privilege(to_regclass('pg_catalog.pg_shmem_allocations'),       'SELECT'),  FALSE) AS shmem_allocations
    ,coalesce(has_table_privilege(to_regclass('pg_catalog.pg_largeobject'),             'SELECT'),  FALSE) AS largeobject
    -- these views read a function that PUBLIC can't execute either: both are needed
    ,coalesce(has_table_privilege(to_regclass('pg_catalog.pg_config'), 'SELECT')
          AND has_function_privilege(to_regprocedure('pg_catalog.pg_config()'), 'EXECUTE'), FALSE) AS config
    ,coalesce(has_table_privilege(to_regclass('pg_catalog.pg_hba_file_rules'), 'SELECT')
          AND has_function_privilege(to_regprocedure('pg_catalog.pg_hba_file_rules()'), 'EXECUTE'), FALSE) AS hba_file_rules
    ,coalesce(has_table_privilege(to_regclass('pg_catalog.pg_replication_origin_status'), 'SELECT')
          AND has_function_privilege(to_regprocedure('pg_catalog.pg_show_replication_origin_status()'), 'EXECUTE'), FALSE) AS replication_origin_status
  \gset svp_
\else
  -- Before 9.4 the scripts only call pgstatindex(text) and pgstatginindex(regclass)
  SELECT
     EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'pgstatindex'    AND oidvectortypes(proargtypes) = 'text'
             AND pg_function_is_visible(oid) AND has_function_privilege(oid, 'EXECUTE')) AS pgstatindex
    ,EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'pgstatginindex' AND oidvectortypes(proargtypes) = 'regclass'
             AND pg_function_is_visible(oid) AND has_function_privilege(oid, 'EXECUTE')) AS pgstatginindex
  \gset svp_
  \set svp_ls_tmpdir FALSE
  \set svp_ls_waldir FALSE
  \set svp_ls_logdir FALSE
  \set svp_pgstathashindex FALSE
  \set svp_pgstattuple_approx FALSE
  \set svp_shmem_allocations FALSE
  \set svp_config FALSE
  \set svp_hba_file_rules FALSE
  \set svp_largeobject FALSE
  \set svp_replication_origin_status FALSE
\endif

-- pg_ls_dir() and pg_read_file() check for superuser in their own code before 11,
-- whatever EXECUTE says; from 11 on EXECUTE is what counts
\if :svp_pg_11
  SELECT
     coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_ls_dir(text)'),                     'EXECUTE'), FALSE) AS ls_dir
    ,coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_read_file(text)'),                  'EXECUTE'), FALSE) AS read_file
    ,coalesce(has_function_privilege(to_regprocedure('pg_catalog.pg_read_file(text, bigint, bigint)'),  'EXECUTE'), FALSE) AS read_file_range
  \gset svp_
\else
  \set svp_ls_dir :svp_rol_super
  \set svp_read_file :svp_rol_super
  \set svp_read_file_range :svp_rol_super
\endif
