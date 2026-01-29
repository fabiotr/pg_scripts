
SET pg_stat_statements.track TO 'none';

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset(), 
  pg_stat_statements_reset()
;

ANALYZE;

SELECT datname AS database AS database, stats_reset FROM pg_stat_database ORDER BY datname;
SELECT 'bgwriter' AS shared_stat, stats_reset FROM pg_stat_bgwriter ;

RESET pg_stat_statements.track;
