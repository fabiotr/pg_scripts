SELECT 
  pg_stat_reset_shared('archiver'), 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset(), 
  pg_stat_statements_reset()
;
