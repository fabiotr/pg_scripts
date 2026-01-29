SELECT 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset(), 
  pg_stat_statements_reset()
;

ANALYZE;

SELECT datname AS database AS database, stats_reset FROM pg_stat_database ORDER BY datname;
SELECT 'bgwriter' AS shared_stat, stats_reset FROM pg_stat_bgwriter ;
