SELECT 
  pg_stat_reset_shared('wal'), 
  pg_stat_reset_shared('archiver'), 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset(), 
  pg_stat_reset_slru('CommitTs'), 
  pg_stat_reset_slru('MultiXactMember'), 
  pg_stat_reset_slru('MultiXactOffset'), 
  pg_stat_reset_slru('Notify'), 
  pg_stat_reset_slru('Serial'),
  pg_stat_reset_slru('Subtrans'), 
  pg_stat_reset_slru('Xact'), 
  pg_stat_reset_slru('other')
\gset svp_

\if :svp_not_aws_rds
  SELECT pg_stat_reset_replication_slot(NULL) AS replication_slot
  \gset svp_
\endif

\if :svp_lib
  \if :svp_ext
    SELECT pg_stat_statements_reset() AS statements
	\gset svp_
  \endif
\endif

\set QUIET off
ANALYZE;
\set QUIET on

\qecho
\qecho '*** Show current stats_reset ***'
\qecho

SELECT datname AS database, stats_reset FROM pg_stat_database WHERE datname IS NOT NULL ORDER BY datname;
SELECT slot_name, stats_reset FROM pg_stat_replication_slots ORDER BY slot_name;

\if :svp_lib
  \if :svp_ext
    SELECT 'pg_stat_statements' AS shared_stat, stats_reset FROM pg_stat_statements_info;
  \endif
\endif

SELECT 'bgwriter' AS shared_stat, stats_reset FROM pg_stat_bgwriter
UNION
SELECT 'archiver' AS shared_stat, stats_reset FROM pg_stat_archiver
UNION
SELECT 'wal' AS shared_stat, stats_reset FROM pg_stat_wal
UNION
SELECT DISTINCT 'slru / ' || name AS shared_stat, stats_reset FROM pg_stat_slru
ORDER BY 2,1;
