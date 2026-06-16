SELECT 
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
