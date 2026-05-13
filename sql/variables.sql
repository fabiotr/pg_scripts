-- Don't show any annoyng messages now
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
    ,current_setting('logging_collector')                  AS logging_collector
    ,current_date                                          AS date
    ,(SELECT rolsuper FROM pg_roles WHERE rolname = user)  AS rol_super
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'track_io_timing'                   AND setting = 'on')   AS track_io
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'pg_stat_statements.track_planning' AND setting = 'on')   AS plan
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'pg_stat_statements.track'          AND setting = 'none') AS track_disabled
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'jit'                               AND setting = 'on')   AS jit
    ,(SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_class    WHERE relname = 'pg_stat_statements'                                   AS not_statements
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'shared_preload_libraries'          AND setting LIKE '%pg_stat_statements%') AS lib
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname IN ('cloudsqladmin', 'rdsadmin'))                        AS not_dbaas
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname = 'cloudsqladmin')                                       AS not_gcp
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname = 'rdsadmin')                                            AS not_rds
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'aurora_compute_plan_id')                                 AS not_aurora
\gset svp_

--Some variables exists only above specific PG versions
\if :svp_pg_90
  SELECT 
    NOT pg_is_in_recovery() AS not_standby,
        pg_is_in_recovery() AS recovery
  \gset svp_
\else
  \set svp_not_standby TRUE
  \set recovery FALSE
\endif

\if :svp_pg_91
  SELECT 
     (SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_stat_replication) AS master
    ,(SELECT CASE WHEN count(1) = 1 THEN TRUE ELSE FALSE END FROM pg_extension WHERE extname = 'pg_stat_statements') AS ext
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_extension WHERE extname = 'pg_stat_statements') AS not_ext
  \gset svp_
\else
  \set svp_master FALSE
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

