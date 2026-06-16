SELECT
  pg_stat_reset_shared('recovery_prefetch'), 
  pg_stat_reset_shared('wal'), 
  pg_stat_reset_shared('archiver'), 
  pg_stat_reset_shared('bgwriter'), 
  pg_stat_reset()
\gset svp_

\if :svp_not_gcp
  SELECT
    pg_stat_reset_slru('CommitTs'),
    pg_stat_reset_slru('MultiXactMember'),
    pg_stat_reset_slru('MultiXactOffset'),
    pg_stat_reset_slru('Notify'),
    pg_stat_reset_slru('Serial'),
    pg_stat_reset_slru('Subtrans'),
    pg_stat_reset_slru('Xact'),
    pg_stat_reset_slru('other')
  \gset svp_
\endif

\if :svp_not_rds
  \if :svp_not_gcp
    SELECT pg_stat_reset_replication_slot(NULL) AS replication_slot
    \gset svp_
  \endif
  SELECT pg_stat_reset_subscription_stats(NULL) AS subscription
  \gset svp_
\endif

\if :svp_lib
  \if :svp_ext
    SELECT pg_stat_statements_reset() AS statements
    \gset svp_
  \endif
\endif

\if :svp_not_standby
  \set QUIET off
  ANALYZE;
  \set QUIET on
\endif
