-- WARNING
-- psql must be >= pg10 to run this script

--Setup
\set QUIET on
\timing off
SET client_encoding TO 'UTF8';

--Vars
SELECT
     (SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname IN ('cloudsqladmin', 'rdsadmin')) AS not_dbaas
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname = 'cloudsqladmin')                AS not_gcp
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_database WHERE datname = 'rdsadmin')                     AS not_rds
    ,(SELECT CASE WHEN count(1) = 0 THEN TRUE ELSE FALSE END FROM pg_settings WHERE name = 'aurora_compute_plan_id')          AS not_aurora
    ,(SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_stat_replication)                                        AS master
    ,NOT pg_is_in_recovery()                               AS not_standby
    ,pg_is_in_recovery()                                   AS recovery
    ,current_setting('logging_collector')                  AS logging_collector
    ,current_setting('server_version')                     AS server_version
    ,current_setting('server_version_num')::int >=  90000  AS pg_90
    ,current_setting('server_version_num')::int >=  90100  AS pg_91
    ,current_setting('server_version_num')::int >=  90500  AS pg_95
    ,current_setting('server_version_num')::int >= 120000  AS pg_12
    ,current_setting('server_version_num')::int >= 140000  AS pg_14
    ,current_date                                          AS date
\gset svp_


\pset footer off
\pset null ' - '
\pset border 1
\pset pager off

-- Markdown format
\o | sed 's/+--/\|--/g' | sed 's/--+/--\|/g' | sed 's/^\s\(\s\+\)/\|\1/' | sed 's/-\[ RECORD .*/\| Info \| Valor \n\|---\|---\|/'

--Report
\qecho '# Report for cluster'
\qecho - Date:     :svp_date
\qecho - Host:     :HOST
\qecho - Port:     :PORT
\qecho - Version:  :SERVER_VERSION_NAME
\qecho


\qecho '# Index'
\qecho
\qecho [[_TOC_]]
\qecho


\qecho '# Cluster'
\qecho

\if :svp_not_dbaas
  \qecho '## Compilation options'
  \qecho
  \i pg_config.sql
  \qecho
\endif

\qecho '## Preset options'
\qecho
\i internal.sql
\qecho

\if :svp_not_gcp
  \qecho '## Shared Memmory use'
  \qecho
  \i shared_buffers_stats.sql
  \qecho
\endif

\if :svp_not_standby
  \if :svp_not_aurora
    \qecho '## Background Workers'
    \qecho
    \i bgwriter.sql
    \qecho
  \endif 

  \qecho '## Checkpoints'
  \qecho
  \i checkpoints.sql
  \qecho

  \if :svp_not_aurora
    \qecho '## Wal'
    \qecho
    \i wal.sql
    \qecho

    \qecho '## Archiver'
    \qecho
    \i archives.sql
    \qecho
  \endif
\endif

\qecho '## WAL files'
\qecho
\i ls_wal.sql
\qecho

\qecho '## Temp files'
\qecho
\i ls_temp.sql
\qecho

\if :svp_not_gcp
  \qecho '### Log files'
  \qecho
  \i ls_logs.sql
  \qecho
\endif

\if :svp_not_dbaas
  \qecho '## Backup'
  \qecho
  \i backup.sql
  \qecho
\endif

\qecho '## I/O Cluster'
\qecho 
\i io_cluster.sql
\qecho

\qecho '## SLRU'
\qecho
\i slru_stats.sql
\qecho

\qecho '## Configurations'
\qecho

\if :svp_not_gcp
  \qecho '### pg_hba.conf'
  \qecho
  \x off
  \i pg_hba.sql
  \qecho
\endif

\qecho '### Authentication configurations'
\qecho 
\i conf_auth.sql
\qecho

\qecho '### SSL configurations'
\qecho
\i conf_ssl.sql
\qecho

\qecho '### Logs configurations'
\qecho
\i conf_logs.sql
\qecho

\qecho '### Resource configurations'
\qecho
\i conf_resource.sql
\qecho

\qecho '### Others configurations'
\qecho
\i conf_others.sql
\qecho

\qecho '## Connections'
\qecho

\qecho '### Connections Total'
\qecho
\i connections_tot.sql
\qecho

\qecho '### Connections by User'
\qecho 
\i connections_by_user.sql
\qecho

\qecho '### Connections SSL'
\qecho
\i connections_ssl.sql
\qecho

\qecho '### Connections GSS'
\qecho
\i connections_gss.sql
\qecho

\qecho '### Connection Running'
\qecho
\i connections_runing.sql
\qecho

\qecho '### Prepared Transactions (Two Phase Commit)'
\qecho
\i prepared_transactions.sql
\qecho

\if :svp_not_standby
  \qecho '## Roles'
  \qecho

  \qecho '### Roles with high privileges'
  \qecho
  \i user_priv.sql
  \qecho

  \qecho '### Roles with options'
  \qecho
  \i user_options.sql
  \qecho

  \qecho '### Granted roles'
  \qecho
  \i user_granted_roles.sql
  \qecho
\endif

\if :svp_pg_90
  \if :svp_recovery

    \qecho '## Replication slave'
    \qecho
    
    \qecho '### Replica conf'
    \qecho
    \i conf_replica.sql
    \qecho
    \qecho '### Recovery conf'
    \i conf_recovery.sql
    \qecho
	
    \if :svp_pg_91
      \qecho '### Conflicts'
      \qecho
      \i database_standby_conflicts.sql
      \qecho
    \endif

    \if :svp_not_aurora
      \qecho '### Wal reciever'
      \qecho
      \i wal_reciever.sql
      \qecho
    \endif
  \endif

  \if :svp_master
    \qecho '## Replication master'
    \qecho

    \qecho '### Master conf'
    \qecho
    \i conf_master.sql
    \qecho
	
    \qecho '### Replication stats'
    \qecho
    \i replication_stats.sql
    \qecho

    \if :svp_pg_95
	  \qecho '### Replication Slots'
      \qecho
      \i replication_slots.sql
      \qecho

      \qecho '### Replication origins'
      \qecho
      \i replication_origin.sql
      \qecho
	\endif
  \endif
\endif

\if :svp_not_standby
  \qecho '## Tablespaces'
  \qecho
  \i tablespaces.sql
  \qecho


  \qecho '## Databases on cluster'
  \qecho
  \i database_size.sql
  \qecho
\endif

\qecho '## Statements from cluster'
\qecho

\qecho '### Statements from cluster by time'
\qecho
\if :svp_pg_14
  \i statements_group_database_resume.sql
\else
  \i statements_group_database_time.sql
\endif
\qecho

\qecho '### Statements from cluster by temp'
\qecho
\i statements_group_database_temp.sql
\qecho

\qecho
\qecho END
\pset footer on
\set QUIET off
