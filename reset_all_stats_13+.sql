SET pg_stat_statements.track TO 'none';

CREATE EXTENSION IF NOT EXISTS pg_stat_staements;

SELECT 
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
  pg_stat_reset_slru('other')
;

ANALYZE;

SELECT datname AS database, stats_reset FROM pg_stat_database ORDER BY datname;
SELECT 'bgwriter' AS shared_stat, stats_reset FROM pg_stat_bgwriter
UNION
SELECT 'archiver' AS shared_stat, stats_reset FROM pg_stat_archiver
UNION
SELECT DISTINCT 'slru' AS shared_stat, stats_reset FROM pg_stat_slru
ORDER BY 2,1;

RESET pg_stat_statements.track;
