# 🐘 PostgreSQL DBA Essentials
> A curated collection of SQL scripts for performance tuning, monitoring, and database maintenance.

[![PostgreSQL Version](https://img.shields.io/badge/PostgreSQL-18+-336791?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/fabiotr/pg_scripts/graphs/commit-activity)

Este repositório contém scripts essenciais para o dia a dia de um DBA ou desenvolvedor que trabalha com PostgreSQL, focando em identificar gargalos de performance e otimização de recursos.

---

## ✨ Highlight Features

What makes this repository essential for managing PostgreSQL instances:
- **🔄 Wide Version Compatibility**: Scripts are carefully crafted to be compatible from **PostgreSQL 8.2 up to the current stable release**.
- **⚡ Version Auto-Detection**: Scripts are designed to automatically detect the running PostgreSQL version to ensure compatibility with specific system catalogs and views.
- **🎯 Zero Dependencies**: All scripts are pure SQL. Just copy, paste, and run — no extra packages required.
- **📊 Smart Reporting**: Detailed reports that clearly shows objects details, performance insights, slow queries and more
 
---

## 🛠️ Requirements

To ensure these scripts run correctly, please check the following prerequisites:

- [x] **PostgreSQL 8.2+**: While most scripts work PostgreSQL 8.2 to the current version (PostgreSQL 18 now). Unfortunately some of then will not work on older versions because some features did not exists on then.
- [x] **psql** client: The standard PostgreSQL command-line tool. Most of this scrips use meta-commands from psql to format output or to choose the correct version of PostgreSQL you are running. Of course you can take the SQL scrip manually and run in any PostgreSQL compatible client.
- [x] **Superuser Access**: Many scripts require access to system catalogs and stats views. 
- [x] **pgstattuple**: Some scripts use this extension to provide information about tables and indexes health.
- [x] **pg_stat_statements**: For performance analysis scripts (like query tracking), ensure this extension is enabled in your `postgresql.conf`:
```conf
shared_preload_libraries = 'pg_stat_statements'
```

---

## 🚀 Quick Start

Para executar qualquer script utilizando o terminal, use o comando abaixo:

```bash
git clone https://github.com/fabiotr/pg_scripts.git
cp pg_scripts/.psqlrc $HOME/

## Usage at shell environment:
psql -f script_name.sql

## Usage at psql prompt:
\i script_name.sql
```
**Note**: Some scripts may require superuser privileges or the pg_stat_statements extension to provide full insights.

---

## ⚠️ Safety & Best Practices

Before running these scripts in a production environment, please consider the following:

> [!WARNING]
> **Use at your own risk:** These scripts are provided as-is. Always test them in a staging or development environment before executing them in production.

- **Performance Overhead:** Some scripts, particularly those calculating **Bloat** or **Table Sizes**, may perform sequential scans or heavy meta-data lookups. On very large databases, this can cause temporary performance degradation.
- **Transaction Locks:** While most scripts are read-only (SELECT), monitoring long-running transactions or locks is critical. Avoid running scripts that create temporary tables during peak hours if your disk I/O is near its limit.
- **Read-Only Intent:** All scripts in this repository are designed for **read-only** diagnostic purposes. They do not perform `DROP`, `DELETE`, or `TRUNCATE` operations. However, always verify the script content before execution.

---

## 📂 Scripts Categories

The scripts are organized into specialized groups to facilitate database management:

- **🔍 Assessment**: Discover existing objects, their structures, and current statistics.
- **🛠️ Maintenance**: Identify potential issues and generate recommendations for fixes.
- **🚀 Migration**: Specialized tools to assist in upgrading to new PostgreSQL versions, handling edge cases and compatibility.
- **⚙️ Object Tuning**: Optimize specific object parameters (tables, indexes) for peak performance.
- **📋 Parameter Tuning**: Audit and review configuration settings applied to your PostgreSQL cluster.
- **⚡ Query Tuning**: Pinpoint resource-heavy queries and identify optimization opportunities.
* **🔗 Replication**: Monitor health, lag, and configuration for PostgreSQL replication setups.
* **🛡️ Security**: Audit your environment to find and fix potential security vulnerabilities.
* **🔥 Troubleshooting**: Emergency scripts for "under fire" situations to diagnose and resolve production incidents quickly.

> **Scope Note:** Each script is designed to run at a specific level: **Cluster-wide**, **Database-specific**, or **Both**.

---

## List of scripts now avaliable

## 📂 Script Catalog

The scripts are organized by functional area and scope. Click on a category to expand the full list.

<details>
<summary>🔍 Assessment (Inventory & Statistics)</summary>

| Scope    | Name | Compatibility | Description | Reference |
| :---     | :--- | :---: | :--- | :--- |
| Cluster  | `archives.sql` | PG >= 9.4 | Amount of WAL archives generated | `pg_stat_archiver` |
| Database | `index_big.sql` | | Indexes > 800KB and > 50% of table size | `pg_index` |
| Database | `index_functions.sql` | | Indexes using expressions on columns | `pg_index` |
| Cluster  | `database_size.sql` | | Databases on cluster: size and options | `pg_database` |
| Database | `index_non_btree.sql` | | Non-BTREE indexes | `pg_index`, `pg_am` |
| Database | `index_non_default_collation.sql` | PG >= 9.1 | Indexes without default collation | `pg_index`, `pg_collation` |
| Database | `index_partial.sql` | | Partial indexes | `pg_index` |
| Database | `index_size.sql` | PG >= 8.3 | Top 20 indexes by size | `pg_class`, `pg_index` |
| Cluster  | `internal.sql` | | Cluster parameters and internal stats | `current_setting` |
| Cluster  | `io_cluster.sql` | PG >= 16 | Cluster-wide I/O statistics | `pg_stat_io` |
| Database | `materialized_views.sql` | PG >= 9.3 | Materialized views inventory | `pg_class` |
| Database | `object_size.sql` | | Top 20 objects by size | `pg_class` |
| Cluster  | `pg_config.sql` | PG >= 9.6 | Compilation and build parameters | `pg_config` |
| Database | `schemas.sql` | | Schema inventory | `pg_namespace` |
| Database | `tables_changes.sql` | | Top 10 tables with most I/U/D activity | `pg_stat_user_tables` |
| database | `tables_delete.sql` | | Top 10 tables with more DELETEs | `pg_stat_user_tables` | |
| Database | `tables_fks.sql` | PG >= 9.5 | Table precedence based on FK inheritance | `pg_constraint` |
| Database | `tables_foreign.sql` | PG >= 9.1 | Foreign Tables using FDW | `pg_foreign_table` |
| database | `tables_insert.sql` | | Top 10 tables with more INSERTs | `pg_stat_user_tables` | |
| Database | `tables_partition.sql` | PG >= 12 | Partitioned tables and indexes | `pg_class`, `pg_inherits` |
| Database | `tables_rule.sql` | | Tables with rules defined | `pg_rules` |
| Database | `tables_size.sql` | PG >= 9.5 | Top 20 tables by size (approximate free space) | `pgstattuple` |
| Database | `tables_unlogged.sql` | PG >= 9.3 | List of unlogged tables | `pg_class` |
| database | `tables_update.sql` | | Top 10 tables with more UPDATEs | `pg_stat_user_tables` | |
| Database | `tablespaces.sql` | | Tablespace inventory | `pg_tablespace` |
| database | `tablespace_objects.sql` | PG >= 9.4     | Number of objects by type for each tablespace | `pg_tablespace` | |
| database | `trigger_events.sql` | PG >= 9.3     | Event Triggers | `pg_event_trigger` | |
| database | `trigger_tables.sql` |               | Table Triggers | `pg_trigger`, `pg_proc` | |
| Database | `views.sql` | | View inventory | `pg_views` |

</details>

<details>
<summary>🛠️ Maintenance (Optimization & Cleanup)</summary>

| Scope | Name | Compatibility | Description | Comments |
| :--- | :--- | :---: | :--- | :--- |
| database | `index_dup.sql`                         |               | Duplicated indexes that have same columns | `pg_index` |  We recommend check manually other differences before drop any index | |
| database | `index_missing_in_fk.sql`               | PG >= 9.4     | Foreign Keys without an associated index on same columns | `pg_constraint` and `pg_index` | | 
| database | `index_missing_in_fk_create.sql`        | PG >= 9.4     | CREATE INDEX command for every Foreign Keys without an associated index on same columns | `pg_constraint` and `pg_index` | |
| database | `index_poor.sql`                        | PG >= 8.4     | Indexes with bad performance based on some criteria | `pg_stat_user_indexes` | We advise that this list don't include other replicas that may use this indexes |
| database | `index_poor_drop.sql`                   |               | DROP INDEX command for every not used index | `pg_stat_user_indexes` | We advise that this list don't include other replicas that may use this indexes |
| database | `index_stat_btree.sql`                  | PG >= 8.3     | Top 20 BTREE indexes that may need a REINDEX (having avg_leaf_density <= 70 OR leaf_fragmentation >= 20) ordered by index size | `pgstatindex(oid)` function on `pgstattuble` extension | Notice that  pgstatindex(oid) may take a wile to run and overhead your I/O |
| database | `index_stat_btree_reindex.sql`          | PG >= 10      | Reindex indexes having avg_leaf_density <= 70 OR leaf_fragmentation >= 20 | `pgstatindex(oid)` function on `pgstattuble` extension | Notice that  pgstatindex(oid) may take a wile to run and overhead your I/O and REINDEX command will generate I/O overhead and may generate small locks. We advise to monitor server while running this | 
| database | `index_stat_gin.sql`                    | PG >= 9.3     | Statistics about top 20 GIN indexes by size | `pgstginatindex(oid)` function on `pgstattuble` extension | Notice that  pgstatginindex(oid) may take a wile to run and overhead your I/O |
| database | `index_stat_hash.sql`                   | PG >= 10      | Statistics about top 20 HASH indexes by size | `pgstathashindex(oid)` function on `pgstattuble` extension | Notice that  pgstathashindex(oid) may take a wile to run and overhead your I/O |
| database | `index_table_missing.sql`               | PG >= 8.4     | Tables that may need new indexes | `pg_stat_user_tables` | We advise that this list don't include other replicas that may use this indexes |
| both     | `reset_all_stats.sql                    | PG >- 9.0     | Reset all stats from current database and cluster | `pg_stat_reset_*` | This script run an ANALYZE command on current database to prevent autovacuum issues |
| database | `tables_bloat_approx.sql`               | PG >= 8.3     | Top 10 tables with more free space | `pgstattuple_aprrox()` function on `pgstattuple` extension | Notice that pgstattuple_aprrox(oid) may take a wile to run and overhead your I/O |
| database | `tables_index_missing.sql`              | PG >= 8.4     | Tables with poor or few indexes and its reasons | `pg_stat_user_tables` | |
| database | `tables_not_used.sql`                   | PG >= 8.3     | Tables with low usage | `pg_stat_user_tables`| |
| database | `tables_not_used_drop.sql`              |               | DROP TABLE commands for tables with low usage | `pg_stat_user_tables` | |
| database | `vacuum_full_or_cluster.sql`            | PG >= 9.5     | VACUUM FULL or CLUSTER commands for tables with more than 20% of free space | `pgstattuple_approx()` function on `pgstattuple` extension | Notice that  pgstattuple_approx(oid) may take a wile to run and overhead your I/O |
| cluster  | `vacuum_wraparound_database.sql`        |               | Databases near a vacuum wraparound order by age | `pg_database` | |
| database | `vacuum_wraparound_table.sql`           | PG >= 9.3     | Tables near a vacuum wraparound order by age | `pg_class` | |
| database | `vacuum_wraparound_table_clean.sql`     | PG >= 9.5     | VACUUM commands to prevent a vacuum wraparound | `pg_class` | |
| database | `vacuum_wraparound_table_multixact.sql` | PG >= 9.5     | Tables near a vacuum wraparound due to multixact age | `pg_class` | |

</details>

<details>
<summary>🚀 Migration (Upgrades & Logical Replication)</summary>

| Scope | Name | Compatibility | Description | Reference |
| :--- | :--- | :---: | :--- | :--- |
| Database | `object_privileges_grant.sql` | PG >= 9.3 | Generates GRANT commands for privileges | `pg_class`, `pg_roles` |
| Database | `reindex_on_new_glibc.sql` | PG >= 9.1 | REINDEX for collation changes (GLIBC 2.28+) | `pg_collation` |
| Database | `sequence_setval.sql` | | Generates setval for sequences | Useful for logical replicas |
| Database | `tables_with_oid.sql` | PG < 12 | Identifies tables using deprecated OIDs | `pg_class` |

</details>

<details>
<summary>🔥 Troubleshooting (Emergency & Active Issues)</summary>

| Scope | Name | Compatibility | Description | Reference |
| :--- | :--- | :---: | :--- | :--- |
| cluster  | `clean_query.sql`                       |               | Ask for an Query ID and show the query without line breaks and spaces | Based on `pg_stat_statements` | Only works on psql |
| cluster  | `connections_by_user.sql`               | PG >= 9.2     | Active connections stats by users | Based on `pg_stat_activity` | |
| cluster  | `connections_gss.sql`                   | PG >= 12      | Active connections stats using GSSAPI  authentication | Based on `pg_stat_gssapi` | |
| cluster  | `connections_running.sql`                |              | Active connections stats running now | Based on `pg_stat_activity` | |
| cluster  | `connections_running_detais.sql`         |              | Active detailed connections stats running now | `pg_stat_activity` | |
| cluster  | `connections_ssl.sql`                   | PG >= 9.5     | Active connections stats using SSL | `pg_stat_activity` | |
| cluster  | `connections_tot.sql`                   | PG >= 9.2     | Total active connections stats running now | `pg_stat_activity` | |
| cluster  | `database_standby_conflicts.sql`        | PG >= 9.1     | Queries canceled on standby due to conflicts with master | `pg_database_conflicts` | |
| database | `index_check_btree_integrity.sql`       | PG >= 10      | Check integrity on every BTREE index | `bt_index_check(oid)` function on `amcheck` extension | | 
| database | `index_check_gin_integrity.sql`         | PG >= 18      | Check integrity on every GIN index | `bt_index_check(oid)` function on `amcheck` extension | |
| database | `index_invalid.sql`                     |               | Indexes marked as invalid | `pg_index` | |
| database | `kill_active_all_wait_fucking_event.sql` | PG >= 9.6    | Kill active sessions that have any wait event type except "Client" | `pg_stat_activity` | |
| database | `kill_active_bufferpin.sql`             | PG >= 9.6     | Kill active sessions that have wait event type "Bufferpin" | `pg_stat_activity` | |
| database | `kill_active_ipc.sql`                   | PG >= 9.6     | Kill active sessions that have wait event type "IPC" | `pg_stat_activity` | |
| database | `kill_active_lwlock.sql`                | PG >= 9.6     | Kill active sessions that have wait event type "LWLock" | `pg_stat_activity` | |
| database | `kill_active_io_query_time_greater_10_seconds.sql` | PG >= 9.6 | Kill active sessions that are running for more than 10 seconds and have wait event type "IO" | `pg_stat_activity` | |
| database | `kill_active_io_query_time_greater_60_seconds.sql` |PG >= 9.6  | Kill active sessions that are running for more than 60 seconds and have wait event type "IO" | `pg_stat_activity` | |
| database | `kill_active_query_time_greater_10_seconds.sql` |       | Kill active sessions that are running for more than 10 seconds | `pg_stat_activity` | |
| database | `kill_active_query_time_greater_60_seconds.sql` |       | Kill active sessions that are running for more than 60 seconds | `pg_stat_activity` | |
| database | `kill_idle_greater_10_minutes.sql`       |              | Kill idle sessions that are running for more than 10 minutes | `pg_stat_activity` | |
| database | `kill_idle_greater_60_minutes.sql`       |              | Kill idle sessions that are running for more than 60 minutes | `pg_stat_activity` | |
| database | `kill_idle_in_transaction_60_seconds.sql` |             | Kill idle in transaction sessions that are running for more than 60 seconds | `pg_stat_activity` | |
| database | `kill_oldest_blocker.sql`               | PG >= 9.6     | Kill oldest locker session | `pg_stat_activity` and `pg_blocking_pids()` function | |
| cluster  | `locks.sql`                             | PG >= 8.3     | Locks | `pg_locks`, `pg_stat_activity` | | 
| cluster  | `pgbouncer_fdw.sql`                     |               | Script to create views to pgBouncer virtual database SHOW commands | `dblink` extension | | 
| cluster  | `prepared_transactions.sql`             |               | Current prepared transactions | `pg_prepared_xacts` | | 
| cluster  | `progress_analyze.sql`                  | PG >= 13      | Status about ANLYZE commands running | `pg_stat_progress_analyze` | |
| cluster  | `progress_basebackup.sql`               | PG >= 13      | Status about pg_basebackup running | `pg_stat_progress_basebackup` | |
| cluster  | `progress_cluster.sql`                  | PG >= 12      | Status about CLUSTER commands running | `pg_stat_progress_cluster` | |
| cluster  | `progress_copy.sql`                     | PG >= 14      | Status about COPY commands running | `pg_stat_progress_copy` | |
| cluster  | `progress_index.sql`                    | PG >= 12      | Status about CREATE INDEX commands running | `pg_stat_progress_create_index` | |
| cluster  | `progress_vacuum.sql`                   | PG >= 9.6     | Status about VACUUM commands running | `pg_stat_progress_vacuum` | |

</details>

<details>
<summary>⚙️ Tuning (Object Optimization)</summary>

| Scope | Name | Compatibility | Description | Reference |
| :--- | :--- | :---: | :--- | :--- |
| database | `autovacuum_analyze.sql`                |               | List ANALYZE and autovacuum ANALYZE stats | `pg_stat_user_tables` | | 
| database | `autovacuum_analyze_adjust.sql`         |               | Recommend autovacuum_analyze_scale_factor adjust based on number of rows on table | `pg_stat_user_tables` | | 
| database | `autovacuum_vacuum.sql`                 | PG >= 8.4     | Top 20 tables with more percentage of dead rows | `pg_stat_all_tables` | |
| database | `autovacuum_vacuum_+.sql`               | PG >= 9.2     | Top 20 tables with more percentage of dead rows with separate values for toast tables | `pg_stat_all_tables`| experimental |
| database | `autovacuum_vacuum_adjust.sql`          | PG >= 8.4     | ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size | Based on `pg_stat_all_tables` |
| database | `autovacuum_vacuum_adjust_+.sql`        | PG >= 8.4     | ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size with separate values for toast tables | `pg_stat_all_tables` | experimental |
| database | `autovacuum_vacuum_queue.sql`           |               | Next tables on autovacuum vacuum queue | `pg_stat_all_tables` | |
| database | `fillfactor.sql`                        | PG >= 8.4     | Tables having more updates and bad hot update ratio | `pg_stat_user_tables` | |
| database | `functions.sql`                         | PG >= 8.4     | Functions consuming more execution time | `pg_stat_user_functions` | |
| database | `object_options.sql`                    |               | Objects with options set | `pg_class` | |
| database | `tables_alignment_padding.sql`          | PG >= 94      | Suggested Columns Reorder | | |
| database | `tables_without_index.sql`              |               | Tables without any index | `pg_class` | |
| database | `tables_without_pk.sql`                 |               | Tables without any Primary Key (PK) | `pg_constraint` | |

</details>

<details>
<summary>⚙️ Tuning (parameters)</summary>

| Scope | Name | Compatibility | Description | Reference |
| :--- | :--- | :---: | :--- | :--- |
| cluster  | `bgwriter.sql`                          | PG >= 17      | Background Workers stats | `pg_stat_bgwriter` | | 
| database | `autovacuum_queue.sql`                  |               | Next tables where autovacuum will work | `pg_stat_user_tables` |  |
| cluster  | `checkpoints.sql`                       | PG >= 8.3     | Checkpoint stats | `pg_stat_checkpointer` |  |
| cluster  | `conf_directories.sql`                  | PG >= 8.4     | Parameters about file and directories location | `pg_settings`| |
| cluster  | `conf_logs.sql`                         |               | Parameters about logs configurations and other related | `pg_settings` | |
| cluster  | `conf_master.sql`                       | PG >= 8.4     | Parameters about master server replication configurations | `pg_settings` | |
| cluster  | `conf_others.sql`                       | PG >= 8.4     | Other parameters with non default values | `pg_settings` | | 
| cluster  | `conf_resource.sql`                     |               | Parameters about resource configuration |  `pg_settings` | | 
| cluster  | `conf_recovery.sql`                     | PG >= 8.4     | Parameters about recovery or at recovery.conf file (PG <12) | `pg_settings` OR `recovery.conf` | |
| cluster  | `conf_replica.sql`                      | PG >= 8.4     | Parameters about replication slave | `pg_settings` | |
| database | `database_stats.sql`                    |               | Database stats | `pg_stat_database` | |
| cluseter | `ls_logs.sql`                           | PG >= 10      | Logs size | `pg_ls_logdir()` function | |
| cluster  | `ls_temp.sql`                           | PG >= 12      | Temporary files size | `pg_ls_tempdir()` function | | 
| cluster  | `ls_wal.sql`                            | PG >= 10      | WAL files size | `pg_ls_waldir()` function | |
| cluster  | `user_options.sql`                      | PG >= 9.0     | Roles with parameter options set | `pg_db_role_setting`| |
| cluster  | `wal.sql`                               | PG >= 14      | Transaction logs (WAL) statistics | `pg_stat_wal` | |

</details>

<details>
<summary>⚙️ Tuning (queries)</summary>

| Scope | Name | Compatibility | Description | Reference |
| :--- | :--- | :---: | :--- | :--- |
| database | `io_index.sql`                          | PG >= 8.4     | I/O stats for indexes | `pg_statio_all_indexes` | |
| database | `io_sequence.sql`                       | PG >= 8.4     | I/O stats for sequences | `pg_statio_all_sequences` | |
| database | `io_table_heap.sql`                     | PG >= 8.4     | I/O stats for heap on tables | `pg_statio_all_tables` | |
| database | `io_table_index.sql`                    | PG >= 9.1     | I/O stats for indexes on tables | `pg_staio_all_tables` | |
| database | `io_table_others.sql`                   | PG >= 9.1     | I/O stats for TOAST and TID on tables | `pg_statio_all_tables` | | 
| database | `statements_calls.sql`                  | PG >= 8.4     | top 10 statements order by calls | `pg_stat_statements` extension | |
| cluster  | `statements_group_database_resume.sql`  | PG >= 14      | top 10 statements on all cluster order by execution time | `pg_stat_statements` extension | |
| cluster  | `statements_group_database_temp.sql`    | PG >= 9.2     | top 10 statements on all cluster order by temporary files | `pg_stat_statements` extension | |
| cluster  | `statements_group_database_time.sql`    | PG >= 9.4     | top 10 statements on all cluster order by execution time | `pg_stat_statements` extension | |
| cluster  | `statements_group_database_total.sql`   | PG >= 14      | total statements summary on all cluster  | `pg_stat_statements` extension | |
| database | `statements_jit.sql`                    | PG >= 15      | top 10 statements order by jit calls | `pg_stat_statements` extension | |
| database | `statements_local.sql`                  | PG >= 9.2     | top 10 statements order by local memory used | `pg_stat_statements` extension | |
| database | `statements_plan.sql`                   | PG >= 14      | top 10 statements planing time | `pg_stat_statements` extension | |
| database | `statements_resume.sql`                 | PG >= 14      | top 20 statements order by planing and execution time | `pg_stat_statements` extension | |
| database | `statements_rows.sql`                   | PG >= 8.4     | top 10 statements order by rows | `pg_stat_statements` extension | |
| database | `statements_rows_call.sql`              | PG >= 8.4     | top 10 statements statistics order by rows per call | `pg_stat_statements` extension | |
| database | `statements_shared.sql`                 | PG >= 9.2     | top 10 statements order by shared memory on disk used | `pg_stat_statements` extension | |
| database | `statements_temp.sql`                   | PG >= 9.2     | top 10 statements order by temporary files | `pg_stat_statements` extension | |
| database | `statements_time.sql`                   | PG >= 8.4     | top 10 statements order by execution time | `pg_stat_statements` extension | |
| database | `statements_top5.sql`                   | PG >= 8.4     | top 5 full query statements order by execution and planing time | `pg_stat_statements` extension | |
| database | `statements_total.sql`                  | PG >= 14      | total statements summary | `pg_stat_statements` extension | |
| database | `statements_wal.sql`                    | PG >= 13      | top 10 statements order by WAL generation | `pg_stat_statements` extension | |
| database | `tables_with_seq_scan.sql`              |               | top 20 tables with more seq scan | `pg_stat_user_tables` | |

</details>

<details>
<summary>🛡️ Security (Auditing & Permissions)</summary>

| Scope | Name | Compatibility | Description | Reference |
| :--- | :--- | :---: | :--- | :--- |
| cluster  | `backup.sql`                            | PG >= 9.1     | Look for a `.backup` file with physical backup summary at pg_wal or pg_xlog | `pg_pg_read_file()` and `pg_ls_dir` functions | | 
| cluster  | `conf_recovery.sql`                     | PG >= 8.4     | parameters about backup recovery | Based on `pg_settings` | |
| cluster  | `connections_gss.sql`                   | PG >= 12      | total connections stats running now using GSS |   `pg_stat_gssapi` | |
| cluster  | `connections_running_ssl.sql`            | PG >= 9.5     | total connections stats running now using SSL | `pg_stat_ssl` | |
| database | `object_privileges_list.sql`            |               | privileges on objects | `pg_class`, `pg_roles` | |
| cluster  | `pg_hba.sql`                            | PG >= 10      | pg_hba.conf non commented lines and erros | `pg_hba_file_rules` | list rules even if they are not active yet after any change on pg_hba.conf file | 
| cluster  | `security_labes.sql`                    | PG >= 9.1     | security labels on SE Linux Security Policies | `pg_seclabels` | |
| database | `security_policies.sql`                 | PG >= 9.5     | policies for Row Level Security | `pg_policies` | |
| database | `user_default_privileges.sql`           | PG >= 9.0     | Default privileges | `pg_default_acl` | |
| database | `user_granted_parameters.sql`           | PG >= 15      | privileges on parameters | `pg_parameter_acl` | |
| cluster  | `user_granted_roles.sql`                |               | granted roles to other roles | `pg_auth_members` | |
| database | `user_owners_x_connections.sql`         |               | current number of connections and objects owned by each role | `pg_stat_activity`, `pg_class` | |
| cluster  | `user_priv.sql`                         |               | roles with hight privileges options like superusers | `pg_roles` | |

</details>

*(Note: For the sake of brevity in this preview, only main scripts are shown. Check the full repository for the complete list.)*
