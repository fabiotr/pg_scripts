\qecho
\qecho '*** Current stats_reset ***'
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
