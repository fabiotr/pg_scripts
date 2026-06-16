\qecho
\qecho '*** Current stats_reset ***'
\qecho

SELECT datname AS database, stats_reset FROM pg_stat_database WHERE datname IS NOT NULL ORDER BY datname;
SELECT slot_name AS replication_slot, stats_reset FROM pg_stat_replication_slots ORDER BY slot_name;
SELECT subname AS subscription, stats_reset FROM pg_stat_subscription_stats ORDER BY subname;

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
SELECT 'recovery_prefetch' AS shared_stat, stats_reset FROM pg_stat_recovery_prefetch
UNION
SELECT DISTINCT 'io' AS shared_stat, stats_reset FROM pg_stat_io
UNION
SELECT DISTINCT 'slru / ' || name AS shared_stat, stats_reset FROM pg_stat_slru
ORDER BY 2,1;
