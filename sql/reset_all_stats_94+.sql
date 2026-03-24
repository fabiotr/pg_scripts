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


\set QUIET off
ANALYZE;
\set QUIET on

\qecho
\qecho '*** Show current stats_reset ***'
\qecho

SELECT datname AS database, stats_reset FROM pg_stat_database WHERE datname IS NOT NULL ORDER BY datname;
SELECT 'bgwriter' AS shared_stat, stats_reset FROM pg_stat_bgwriter
UNION
SELECT 'archiver' AS shared_stat, stats_reset FROM pg_stat_archiver
ORDER BY 2,1;
