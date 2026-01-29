SET pg_stat_statements.track TO 'none';

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT 
  pg_stat_reset_shared('io'), 
  pg_stat_reset_shared('recovery_prefetch'), 
  pg_stat_reset_shared('wal'), 
  pg_stat_reset_shared('archiver'), 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset(), 
  pg_stat_statements_reset(),
  pg_stat_reset_slru('CommitTs'),
  pg_stat_reset_slru('MultiXactMember'),
  pg_stat_reset_slru('MultiXactOffset'),
  pg_stat_reset_slru('Notify'),
  pg_stat_reset_slru('Serial'),
  pg_stat_reset_slru('Subtrans'),
  pg_stat_reset_slru('Xact'),
  pg_stat_reset_slru('other'),
  CASE WHEN (SELECT CASE WHEN count(1) = 0 THEN TRUE END FROM pg_database WHERE datname = 'rdsadmin')
       THEN pg_stat_reset_replication_slot(NULL) END,
  CASE WHEN (SELECT CASE WHEN count(1) = 0 THEN TRUE END FROM pg_database WHERE datname = 'rdsadmin')
        THEN pg_stat_reset_subscription_stats(NULL) END
\gset

ANALYZE;

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
SELECT DISTINCT 'slru' AS shared_stat, stats_reset FROM pg_stat_slru
UNION
SELECT 'pg_stat_statements' AS shared_stat, stats_reset FROM pg_stat_statements_info
ORDER BY 2,1;

RESET pg_stat_statements.track;
