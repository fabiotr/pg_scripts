SET pg_stat_statements.track TO 'none';

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT 
  pg_stat_reset_shared('archiver'), 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset(), 
  pg_stat_statements_reset()
\gset

\set QUIET off
ANALYZE;
\set QUIET on

\qecho
\qecho '*** Show current stats_reset ***'
\qecho

SELECT datname AS database, stats_reset FROM pg_stat_database ORDER BY datname;
SELECT 'bgwriter' AS shared_stat, stats_reset FROM pg_stat_bgwriter
UNION
SELECT 'archiver' AS shared_stat, stats_reset FROM pg_stat_archiver
ORDER BY 2,1;

RESET pg_stat_statements.track;
