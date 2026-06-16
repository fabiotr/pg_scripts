SELECT 
  pg_stat_reset_shared('bgwriter') AS shared, 
  pg_stat_reset() AS :svp_db
\gset svp_

\if :svp_lib
  SELECT pg_stat_statements_reset() AS statements
  \gset svp_
\endif 

\if :svp_not_standby
  ANALYZE;
\endif
