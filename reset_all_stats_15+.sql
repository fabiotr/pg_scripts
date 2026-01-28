SELECT 
  pg_stat_reset_shared('recovery_prefetch'), 
  pg_stat_reset_shared('wal'), 
  pg_stat_reset_shared('archiver'), 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset(), 
  pg_stat_statements_reset()
;

SET pg_stat_statements.track TO 'none';
ANALYZE VERBOSE;
RESET pg_stat_statements.track;
