\qecho
\qecho '*** Current stats_reset ***'
\qecho

SELECT datname AS database, stats_reset FROM pg_stat_database WHERE datname IS NOT NULL ORDER BY datname;
SELECT 'bgwriter' AS shared_stat, stats_reset FROM pg_stat_bgwriter;
