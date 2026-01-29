SET pg_stat_statements.track TO 'none';

CREATE EXTENSION IF NOT EXISTS pg_stat_staements;

SELECT 
  pg_stat_reset_shared(), 
  pg_stat_reset(), 
  pg_stat_statements_reset();

ANALYZE VERBOSE;

SELECT datname AS database, stats_reset FROM pg_stat_database ORDER BY datname;
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
RESET pg_stat_statements.track;
