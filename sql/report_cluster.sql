-- WARNING
-- psql must be >= pg10 to run this script

--Setup
\set QUIET on
\timing off
SET client_encoding TO 'UTF8';
--SET pg_stat_statements.track TO none;
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
    ,current_setting('server_version_num')::int >= 170000  AS pg_17
    ,current_date                                          AS date
\gset svp_


\pset footer off
\pset null ' - '
\pset border 1
\pset pager off

-- Markdown format
\o | sed 's/+--/\|--/g' | sed 's/--+/--\|/g' | sed 's/^\s\(\s\+\)/\|\1/' | sed 's/-\[ RECORD .*/\| Info \| Value \n\|---\|---\|/'

--Report
\qecho '# 🐘 Report for Cluster'
\qecho - Date:     :svp_date
\qecho - Host:     :HOST
\qecho - Port:     :PORT
\qecho - Version:  :SERVER_VERSION_NAME
\qecho


\qecho '## 📌 Index'
\qecho
\qecho [[_TOC_]]
\qecho


\qecho '## 🐘 Cluster Stats'
\qecho

\if :svp_not_dbaas
  \qecho '### 🛠️ Compilation Options'
  \qecho
  \qecho '| Info | Value'
  \qecho '|---|---|'
  \i pg_config.sql
  \qecho
\endif

\qecho '### ⚙️ Preset Options'
\qecho
\i internal.sql
\qecho

\if :svp_not_gcp
  \qecho '### 📊 Shared Memory Use'
  \qecho
  \i shared_buffers_stats.sql
  \qecho
\endif

\if :svp_not_standby
  \if :svp_not_aurora
    \if :svp_pg_17
      \qecho '### ⚙️ Background Workers'
      \qecho
      \i bgwriter.sql
      \qecho
    \endif
  \endif 

  \qecho '### 📊 Checkpoints'
  \qecho
  \i checkpoints.sql
  \qecho

  \if :svp_not_aurora
    \qecho '### 📊 Write Ahead Log (WAL)'
    \qecho
    \i wal.sql
    \qecho

    \qecho '### 📂 Archiver'
    \qecho
    \i archives.sql
    \qecho
  \endif
\endif

\qecho '## 📊 WAL Files'
\qecho
\i ls_wal.sql
\qecho

\qecho '## 📂 Temp Files'
\qecho
\i ls_temp.sql
\qecho

\if :svp_not_gcp
  \qecho '## 📂 Log Files'
  \qecho
  \i ls_logs.sql
  \qecho
\endif

\if :svp_not_dbaas
  \qecho '## 🛡️ Backup'
  \qecho
  \i backup.sql
  \qecho
\endif

\qecho '## 📊 I/O Cluster'
\qecho 
\i io_cluster.sql
\qecho

\qecho '## 📊 SLRU'
\qecho
\i slru_stats.sql
\qecho

\qecho '## ⚙️ Configurations'
\qecho

\if :svp_not_gcp
  \qecho '### 🛡️ pg_hba.conf'
  \qecho
  \i pg_hba.sql
  \qecho
\endif

\qecho '### 🛡️ Authentication Configurations'
\qecho 
\i conf_auth.sql
\qecho

\qecho '### 🛡️ SSL Configurations'
\qecho
\i conf_ssl.sql
\qecho

\qecho '### ⚙️ Log Configurations'
\qecho
\i conf_logs.sql
\qecho

\qecho '### ⚙️ Resource Configurations'
\qecho
\i conf_resource.sql
\qecho

\qecho '### ⚙️ Other Configurations'
\qecho
\i conf_others.sql
\qecho

\qecho '## 📊 Connections'
\qecho

\qecho '### 📊 Connections Total'
\qecho
\i connections_tot.sql
\qecho

\qecho '### 📊 Connections by User'
\qecho 
\i connections_by_user.sql
\qecho

\qecho '### 🛡️ Connections SSL'
\qecho
\i connections_ssl.sql
\qecho

\qecho '### 🛡️ Connections GSS'
\qecho
\i connections_gss.sql
\qecho

\qecho '### 📊 Connections Running'
\qecho
\i connections_running.sql
\qecho

\qecho '### 📊 Prepared Transactions (Two Phase Commit)'
\qecho
\i prepared_transactions.sql
\qecho

\if :svp_not_standby
  \qecho '## 🛡️ Roles'
  \qecho

  \qecho '### 🛡️ Roles with High Privileges'
  \qecho
  \i user_priv.sql
  \qecho

  \qecho '### 🛡️ Roles with Options'
  \qecho
  \i user_options.sql
  \qecho

  \qecho '### 🛡️ Granted Roles'
  \qecho
  \i user_granted_roles.sql
  \qecho
\endif

\if :svp_pg_90
  \if :svp_recovery

    \qecho '## 🚀 Replication Slave'
    \qecho
    
    \qecho '### 🚀 Replica Conf'
    \qecho
    \i conf_replica.sql
    \qecho
    \qecho '### 🚀 Recovery Conf'
    \i conf_recovery.sql
    \qecho
	
    \if :svp_pg_91
      \qecho '### 🚀 Conflicts'
      \qecho
      \i database_standby_conflicts.sql
      \qecho
    \endif

    \if :svp_not_aurora
      \qecho '### 🚀 WAL Receiver'
      \qecho
      \i wal_receiver.sql
      \qecho
    \endif
  \endif

  \if :svp_master
    \qecho '## 🚀 Replication Master'
    \qecho

    \qecho '### 🚀 Master Conf'
    \qecho
    \i conf_master.sql
    \qecho
	
    \qecho '### 🚀 Replication Stats'
    \qecho
    \i replication_stats.sql
    \qecho

    \if :svp_pg_95
	  \qecho '### 🚀 Replication Slots'
      \qecho
      \i replication_slots.sql
      \qecho

      \qecho '### 🚀 Replication Origins'
      \qecho
      \i replication_origin.sql
      \qecho
	\endif
  \endif
\endif

\if :svp_not_standby
  \qecho '## 📂 Tablespaces'
  \qecho
  \i tablespaces.sql
  \qecho


  \qecho '## 📂 Databases on Cluster'
  \qecho
  \i database_size.sql
  \qecho
\endif

\qecho '## 📊 Statements from Cluster'
\qecho

\qecho
\if :svp_pg_14
  \qecho '### 📊 Statements Total on Cluster'
  \qecho
  \i statements_group_total.sql
  \qecho

  \qecho '### 📊 Statements Total Grouped by Database'
  \qecho 
  \i statements_group_database_total.sql
  \qecho

  \qecho '### 📊 Statements Resume from Cluster by Time'
  \qecho
  \i statements_group_database_resume.sql
  \qecho
\else
  \qecho '### 📊 Statements from Cluster by Time'
  \qecho
  \i statements_group_database_time.sql
  \qecho
\endif

\qecho '### 📊 Statements from Cluster by Temp'
\qecho
\i statements_group_database_temp.sql
\qecho

\qecho
\qecho END
\pset footer on
--\timing on
--RESET client_encoding;
--RESET pg_stat_statements.track;
--\set QUIET off
