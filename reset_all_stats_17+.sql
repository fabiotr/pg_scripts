SELECT 
  pg_stat_reset_shared(), 
  pg_stat_reset(), 
  pg_stat_statements_reset();

SET pg_stat_statements.track TO 'none';
ANALYZE VERBOSE;
RESET pg_stat_statements.track;
