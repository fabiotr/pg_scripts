SELECT 
  pg_stat_reset_shared('archiver'), 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset() 
\gset svp_

\if :svp_lib
  \if :svp_ext
    SELECT pg_stat_statements_reset() AS statements;
  \endif
\endif


\if :svp_not_standby
  \set QUIET off
  ANALYZE;
  \set QUIET on
\endif
