SELECT 
  pg_stat_reset_shared('io') AS io, 
  pg_stat_reset_shared('recovery_prefetch') AS recovery_prefetch, 
  pg_stat_reset_shared('wal') AS wal, 
  pg_stat_reset_shared('archiver') AS archiver, 
  pg_stat_reset_shared('bgwriter') AS bgwriter, 
  pg_stat_reset()
\gset

\if :svp_not_gcp
  SELECT 
    pg_stat_reset_slru('CommitTs') AS slru_commit_ts,
    pg_stat_reset_slru('MultiXactMember') AS slru_multixact_member,
    pg_stat_reset_slru('MultiXactOffset') AS slru_multixact_offset,
    pg_stat_reset_slru('Notify') AS slru_notify,
    pg_stat_reset_slru('Serial') AS slru_serial,
    pg_stat_reset_slru('Subtrans') AS slru_subtrans,
    pg_stat_reset_slru('Xact') AS slru_xact,
    pg_stat_reset_slru('other') AS slru_other
  \gset
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
