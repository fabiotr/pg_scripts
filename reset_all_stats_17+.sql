SELECT 
  pg_stat_reset_shared(), 
  pg_stat_reset(), 
  pg_stat_statements_reset(),
  CASE WHEN (SELECT CASE WHEN count(1) = 0 THEN TRUE END FROM pg_database WHERE datname = 'rdsadmin')
       THEN pg_stat_reset_replication_slot(NULL) END,
  CASE WHEN (SELECT CASE WHEN count(1) = 0 THEN TRUE END FROM pg_database WHERE datname = 'rdsadmin')
        THEN pg_stat_reset_subscription_stats(NULL) END
\gset

\set QUIET off
ANALYZE;
\set QUIET on

\qecho
\qecho '*** Show current stats_reset ***'
\qecho

SELECT datname AS database, stats_reset FROM pg_stat_database ORDER BY datname;
SELECT slot_name, stats_reset FROM pg_stat_replication_slots ORDER BY slot_name;
SELECT subname AS subscription, stats_reset FROM pg_stat_subscription_stats ORDER BY subname;
SELECT 'bgwriter' AS shared_stat, stats_reset FROM pg_stat_bgwriter
UNION
SELECT 'archiver' AS shared_stat, stats_reset FROM pg_stat_archiver
UNION
SELECT 'wal' AS shared_stat, stats_reset FROM pg_stat_wal
UNION
SELECT 'recovery_prefetch' AS shared_stat, stats_reset FROM pg_stat_recovery_prefetch
UNION
SELECT DISTINCT 'io' AS shared_stat, stats_reset FROM pg_stat_io
UNION
SELECT DISTINCT 'checkpointer' AS shared_stat, stats_reset FROM pg_stat_checkpointer
UNION
SELECT DISTINCT 'slru' AS shared_stat, stats_reset FROM pg_stat_slru
UNION
SELECT 'pg_stat_statements' AS shared_stat, stats_reset FROM pg_stat_statements_info
ORDER BY 2,1;
