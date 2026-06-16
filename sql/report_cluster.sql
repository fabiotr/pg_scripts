-- WARNING
-- psql must be >= pg10 to run this script
\ir variables.sql

--Setup
SET client_encoding TO 'UTF8';

\pset footer off
\pset null ' - '
\pset border 1
\pset pager off

-- Markdown format
\o | sed 's/+--/\|--/g' | sed 's/--+/--\|/g' | sed 's/^\s\(\s\+\)/\|\1/' | sed 's/-\[ RECORD .*/\| Info \| Value \n\|---\|---\|/'

--Report
\qecho '# 🐘 Report for cluster'
\qecho '- Date:    ' :svp_date
\qecho '- Host:    ' :HOST
\qecho '- Port:    ' :PORT
\qecho '- Version: ' :SERVER_VERSION_NAME
\qecho


\qecho '# 📌 Index'
\qecho
\qecho [[_TOC_]]
\qecho


\qecho '# 📊 Cluster'
\qecho

\if :svp_not_dbaas
  \qecho '## 🛠️ Compilation options'
  \qecho
  \qecho '| Info | Value'
  \qecho '|---|---|'
  \i pg_config.sql
  \qecho
\endif

\qecho '## ⚙️ Preset options'
\qecho
\ir internal.sql
\qecho

\qecho '## Status last reset'
\qecho
\ir stats_last_reset.sql

\if :svp_not_gcp
  \qecho '## 📊 Shared Memory use'
  \qecho
  \ir shared_buffers_stats.sql
  \qecho
\endif

\if :svp_not_standby
  \if :svp_not_aurora
    \if :svp_pg_17
      \qecho '## ✨ Background Workers'
      \qecho
      \ir bgwriter.sql
      \qecho
    \endif
  \endif 

  \qecho '## 🛠️ Checkpoints'
  \qecho
  \ir checkpoints.sql
  \qecho

  \if :svp_not_aurora
    \qecho '## 🚀 Write Ahead Log (WAL)'
    \qecho
    \ir wal.sql
    \qecho

    \qecho '## 🛠️ Archiver'
    \qecho
    \ir archives.sql
    \qecho
  \endif
\endif

\qecho '## 🚀 WAL files'
\qecho
\ir ls_wal.sql
\qecho

\qecho '## 🛠️ Temp files'
\qecho
\ir ls_temp.sql
\qecho

\if :svp_not_gcp
  \qecho '## 🛠️ Log files'
  \qecho
  \ir ls_logs.sql
  \qecho
\endif

\if :svp_not_dbaas
  \qecho '## 🛡️ Backup'
  \qecho
  \ir backup.sql
  \qecho
\endif

\qecho '## 📊 I/O Cluster'
\qecho 
\ir io_cluster.sql
\qecho

\if :svp_not_aurora
  \qecho '## I/O Cluster Writes'
  \qecho
  \ir io_cluster_write.sql
  \qecho
\endif

\qecho '## 📊 SLRU'
\qecho
\ir slru_stats.sql
\qecho

\qecho '## 🛠️ Configurations'
\qecho

\if :svp_not_gcp
  \qecho '### pg_hba.conf'
  \qecho
  \ir pg_hba.sql
  \qecho
\endif

\qecho '### Authentication configurations'
\qecho 
\ir conf_auth.sql
\qecho

\qecho '### SSL configurations'
\qecho
\ir conf_ssl.sql
\qecho

\qecho '### Log configurations'
\qecho
\ir conf_logs.sql
\qecho

\qecho '### Resource configurations'
\qecho
\ir conf_resource.sql
\qecho

\qecho '### Other configurations'
\qecho
\ir conf_others.sql
\qecho

\qecho '## 📊 Connections'
\qecho

\qecho '### Connections Total'
\qecho
\ir connections_tot.sql
\qecho

\qecho '### Connections by Database'
\qecho
\ir connections_by_database.sql
\qecho

\qecho '### Connections by User'
\qecho 
\ir connections_by_user.sql
\qecho

\qecho '### Connections SSL'
\qecho
\ir connections_ssl.sql
\qecho

\qecho '### Connections GSS'
\qecho
\ir connections_gss.sql
\qecho

\qecho '### Connections Running'
\qecho
\ir connections_running.sql
\qecho

\qecho '### Connections blocking vacuum'
\qecho
\ir connections_blocking_vacuum.sql
\qecho

\qecho '### Vaccum delayed by'
\qecho
\ir vacuum_blocker.sql
\qecho

\qecho '### Prepared Transactions (Two Phase Commit)'
\qecho
\ir prepared_transactions.sql
\qecho

\if :svp_not_standby
  \qecho '## 🛡️ Roles'
  \qecho

  \qecho '### Roles with high privileges'
  \qecho
  \ir user_priv.sql
  \qecho

  \qecho '### Roles with options'
  \qecho
  \ir user_options.sql
  \qecho

  \qecho '### Granted roles'
  \qecho
  \ir user_granted_roles.sql
  \qecho
\endif

\if :svp_pg_90
  \if :svp_recovery

    \qecho '## 🚀 Replication slave'
    \qecho
    
    \qecho '### Replica conf'
    \qecho
    \ir conf_replica.sql
    \qecho
    \qecho '### Recovery conf'
    \ir conf_recovery.sql
    \qecho
	
    \if :svp_pg_91
      \qecho '### Conflicts'
      \qecho
      \ir database_standby_conflicts.sql
      \qecho
    \endif

    \if :svp_not_aurora
      \qecho '### WAL receiver'
      \qecho
      \ir wal_receiver.sql
      \qecho
    \endif
  \endif

  \if :svp_master
    \qecho '## 🚀 Replication master'
    \qecho

    \qecho '### Master conf'
    \qecho
    \ir conf_master.sql
    \qecho
	
    \qecho '### Replication stats'
    \qecho
    \ir replication_stats.sql
    \qecho

    \if :svp_pg_95
      \qecho '### Replication Slots'
      \qecho
      \ir replication_slots.sql
      \qecho

      \if :svp_not_gcp
        \qecho '### Replication origins'
        \qecho
        \ir replication_origin.sql
        \qecho
      \endif
    \endif
  \endif
\endif

\if :svp_not_standby
  \qecho '## 📂 Tablespaces'
  \qecho
  \ir tablespaces.sql
  \qecho


  \qecho '## 📂 Databases on cluster'
  \qecho
  \ir database_size.sql
  \qecho
\endif

\qecho '## 📊 Statements from cluster'
\qecho

\qecho
\if :svp_pg_14
  \qecho '### Statements total on cluster'
  \qecho
  \ir statements_group_total.sql
  \qecho

  \qecho '### Statements total grouped by database'
  \qecho 
  \ir statements_group_database_total.sql
  \qecho

  \qecho '### Statements summary from cluster by time'
  \qecho
  \ir statements_group_database_summary.sql
  \qecho
\else
  \qecho '### Statements from cluster by time'
  \qecho
  \ir statements_group_database_time.sql
  \qecho
\endif

\qecho '### Statements from cluster by temp'
\qecho
\ir statements_group_database_temp.sql
\qecho

\qecho
\qecho END
\pset footer on
--\timing on
--RESET client_encoding;
--RESET pg_stat_statements.track;
--\set QUIET off
