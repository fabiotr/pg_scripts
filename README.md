# 🐘 PostgreSQL DBA Essentials
> A curated collection of SQL scripts for performance tuning, monitoring, and database maintenance.

[![PostgreSQL 8.2–18](https://img.shields.io/badge/PostgreSQL-8.2--18-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/fabiotr/pg_scripts/graphs/commit-activity)

---

## 📌 Table of Contents
- [✨ Highlight Features](#-highlight-features)
- [🛠️ Requirements](#️-requirements)
- [🚀 Quick Start](#-quick-start)
- [📂 SQL Script Catalog](#-sql-script-catalog)
- [🐚 Shell Scripts](#-shell-scripts)
- [⚠️ Safety & Best Practices](#️-safety--best-practices)
- [🤝 Contributing](#-contributing)

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

### 1. Installation
Clone the repository and optionally set up the recommended `psqlrc` for better output formatting:

```bash
git clone https://github.com/fabiotr/pg_scripts.git
cd pg_scripts
# Optional: Use our optimized psql configuration
cp psqlrc ~/.psqlrc
```

### 2. Execution
You can run the scripts directly from your shell or inside a `psql` session.

**From the terminal:**
```bash
psql -h localhost -U postgres -d my_database -f sql/tables_size.sql
```

**From the psql prompt:**
```sql
\i sql/tables_size.sql
```

**Using the provided wrapper (to run on all databases):**
```bash
# Edit comando.sql to choose which script to run
echo "\i sql/tables_size.sql" > comando.sql
./shell/exec_comando.sh
```

---

## 📂 SQL Script Catalog

The scripts are organized by functional area and scope. Click on a category to expand the full list.

<details>
<summary>📊 Reports (Complete Database & Cluster Audits)</summary>

| Scope    | Name                  | Compatibility | Description                                                                                                               | 
| :---     | :---                  | :---:         | :---                                                                                                                      | 
| Cluster  | `report_cluster.sql`  | PG >= 10      | **Full Cluster Audit**: Generates a comprehensive Markdown report including config, connections, replication, and more.   |
| Database | `report_database.sql` | PG >= 10      | **Full Database Audit**: Generates a detailed report of the current database including sizes, bloating, and index health. |

</details>

<details>
<summary>🔍 Assessment (Inventory & Statistics)</summary>

| Scope    | Name                              | Compatibility | Description                                      | Reference |
| :---     | :---                              | :---:         | :---                                             | :--- |
| Cluster  | `archives.sql`                    | PG >= 9.4     | Amount of WAL archives generated                 | `pg_stat_archiver` |
| Database | `extensions.sql`                  | PG >= 9.0     | List all installed extensions                    | `pg_extension` |
| Database | `index_big.sql`                   |               | Indexes > 800KB and > 50% of table size          | `pg_index` |
| Database | `index_functions.sql`             |               | Indexes using expressions on columns             | `pg_index` |
| Cluster  | `database_size.sql`               |               | Databases on cluster: size and options           | `pg_database` |
| Database | `index_non_btree.sql`             |               | Non-BTREE indexes                                | `pg_index`, `pg_am` |
| Database | `index_non_default_collation.sql` | PG >= 9.1     | Indexes without default collation                | `pg_index`, `pg_collation` |
| Database | `index_partial.sql`               |               | Partial indexes                                  | `pg_index` |
| Database | `index_size.sql`                  | PG >= 8.3     | Top 20 indexes by size                           | `pg_class`, `pg_index` |
| Cluster  | `internal.sql`                    |               | Cluster parameters and internal stats            | `current_setting` |
| Cluster  | `io_cluster.sql`                  | PG >= 16      | Cluster-wide I/O statistics                      | `pg_stat_io` |
| Database | `materialized_views.sql`          | PG >= 9.3     | Materialized views inventory                     | `pg_class` |
| Database | `object_size.sql`                 |               | Top 20 objects by size                           | `pg_class` |
| Cluster  | `pg_config.sql`                   | PG >= 9.6     | Compilation and build parameters                 | `pg_config` |
| Database | `schemas.sql`                     |               | Schema inventory                                 | `pg_namespace` |
| Database | `tables_changes.sql`              |               | Top 10 tables with most I/U/D activity           | `pg_stat_user_tables` |
| Database | `tables_delete.sql`               |               | Top 10 tables with more DELETEs                  | `pg_stat_user_tables` |
| Database | `tables_fks.sql`                  | PG >= 9.5     | Table precedence based on FK inheritance         | `pg_constraint` |
| Database | `tables_foreign.sql`              | PG >= 9.1     | Foreign Tables using FDW                         | `pg_foreign_table` |
| Database | `tables_insert.sql`               |               | Top 10 tables with more INSERTs                  | `pg_stat_user_tables` |
| Database | `tables_partition.sql`            | PG >= 12      | Partitioned tables and indexes                   | `pg_class`, `pg_inherits` |
| Database | `tables_rule.sql`                 |               | Tables with rules defined                        | `pg_rules` |
| Database | `tables_size.sql`                 | PG >= 9.5     | Top 20 tables by size (approximate free space)   | `pgstattuple` |
| Database | `tables_unlogged.sql`             | PG >= 9.3     | List of unlogged tables                          | `pg_class` |
| Database | `tables_update.sql`               |               | Top 10 tables with more UPDATEs                  | `pg_stat_user_tables` |
| Database | `tablespaces.sql`                 |               | Tablespace inventory                             | `pg_tablespace` |
| Database | `tablespace_objects.sql`          | PG >= 9.4     | Number of objects by type for each tablespace    | `pg_tablespace` |
| Database | `trigger_events.sql`              | PG >= 9.3     | Event Triggers                                   | `pg_event_trigger` |
| Database | `trigger_tables.sql`              |               | Table Triggers                                   | `pg_trigger`, `pg_proc` |
| Database | `views.sql`                       |               | View inventory                                   | `pg_views` |

</details>

<details>
<summary>🛠️ Maintenance (Optimization & Cleanup)</summary>

| Scope    | Name                                    | Compatibility | Description                                                                             | Comments |
| :---     | :---                                    | :---:         | :---                                                                                    | :--- |
| database | `index_dup.sql`                         |               | Duplicated indexes that have same columns                                               | We recommend checking manually other differences before dropping any index |
| database | `index_missing_in_fk.sql`               | PG >= 9.4     | Foreign Keys without an associated index on same columns                                | `pg_constraint` and `pg_index` |
| database | `index_missing_in_fk_create.sql`        | PG >= 9.4     | CREATE INDEX command for every Foreign Keys without an associated index on same columns | `pg_constraint` and `pg_index` |
| database | `index_poor.sql`                        | PG >= 8.4     | Indexes with bad performance based on some criteria                                     | We advise that this list doesn't include other replicas that may use these indexes |
| database | `index_poor_drop.sql`                   |               | DROP INDEX command for every not used index                                             | We advise that this list doesn't include other replicas that may use these indexes |
| database | `index_stat_btree.sql`                  | PG >= 8.3     | Top 20 BTREE indexes that may need a REINDEX                                            | Notice that `pgstatindex(oid)` may take a while to run and overhead your I/O |
| database | `index_stat_btree_reindex.sql`          | PG >= 10      | Reindex indexes having bad density or fragmentation                                     | Notice that `pgstatindex(oid)` may take a while to run and overhead your I/O. REINDEX command will generate I/O overhead and may generate small locks. |
| database | `index_stat_gin.sql`                    | PG >= 9.3     | Statistics about top 20 GIN indexes by size                                             | Notice that `pgstatginindex(oid)` may take a while to run and overhead your I/O |
| database | `index_stat_hash.sql`                   | PG >= 10      | Statistics about top 20 HASH indexes by size                                            | Notice that `pgstathashindex(oid)` may take a while to run and overhead your I/O |
| database | `index_table_missing.sql`               | PG >= 8.4     | Tables that may need new indexes                                                        | We advise that this list doesn't include other replicas that may use these indexes |
| both     | `reset_all_stats.sql`                   | PG >= 9.0     | Reset all stats from current database and cluster                                       | This script runs an ANALYZE command on current database to prevent autovacuum issues |
| database | `tables_bloat_approx.sql`               | PG >= 8.3     | Top 10 tables with more free space                                                      | Notice that `pgstattuple_approx(oid)` may take a while to run and overhead your I/O |
| database | `tables_index_missing.sql`              | PG >= 8.4     | Tables with poor or few indexes and its reasons                                         | `pg_stat_user_tables` |
| database | `tables_not_used.sql`                   | PG >= 8.3     | Tables with low usage                                                                   | `pg_stat_user_tables`|
| database | `tables_not_used_drop.sql`              |               | DROP TABLE commands for tables with low usage                                           | `pg_stat_user_tables` |
| database | `vacuum_full_or_cluster.sql`            | PG >= 9.5     | VACUUM FULL or CLUSTER commands for tables with more than 20% of free space             | Notice that `pgstattuple_approx(oid)` may take a while to run and overhead your I/O |
| cluster  | `vacuum_wraparound_database.sql`        |               | Databases near a vacuum wraparound order by age                                         | `pg_database` |
| database | `vacuum_wraparound_table.sql`           | PG >= 9.3     | Tables near a vacuum wraparound order by age                                            | `pg_class` |
| database | `vacuum_wraparound_table_clean.sql`     | PG >= 9.5     | VACUUM commands to prevent a vacuum wraparound                                          | `pg_class` |
| database | `vacuum_wraparound_table_multixact.sql` | PG >= 9.5     | Tables near a vacuum wraparound due to multixact age                                    | `pg_class` |

</details>

<details>
<summary>🚀 Migration (Upgrades & Logical Replication)</summary>

| Scope    | Name                          | Compatibility | Description                                 | Reference |
| :---     | :---                          | :---:         | :---                                        | :--- |
| Database | `object_privileges_grant.sql` | PG >= 9.3     | Generates GRANT commands for privileges     | `pg_class`, `pg_roles` |
| Database | `reindex_on_new_glibc.sql`    | PG >= 9.1     | REINDEX for collation changes (GLIBC 2.28+) | `pg_collation` |
| Database | `sequence_setval.sql`         |               | Generates setval for sequences              | Useful for logical replicas |
| Database | `tables_with_oid.sql`         | PG < 12       | Identifies tables using deprecated OIDs     | `pg_class` |

</details>

<details>
<summary>🔗 Replication (High Availability & Logical/Physical)</summary>

| Scope    | Name                         | Compatibility | Description                         | Reference |
| :---     | :---                         | :---:         | :---                                | :--- |
| Cluster  | `replication_stats.sql`      | PG >= 9.1     | Physical replication status and lag | `pg_stat_replication` |
| Cluster  | `replication_slots.sql`      | PG >= 9.4     | Replication slots status            | `pg_stat_replication_slots` |
| Cluster  | `replication_origin.sql`     | PG >= 9.5     | Replication origins                 | `pg_replication_origin_status` |
| Cluster  | `wal_reciever.sql`           | PG >= 9.6     | WAL receiver process statistics     | `pg_stat_wal_receiver` |
| Cluster  | `publications.sql`           | PG >= 10      | Logical replication publications    | `pg_publication` |
| Cluster  | `publication_schemas.sql`    | PG >= 15      | Schemas included in publications    | `pg_publication_namespace` |
| Cluster  | `publication_tables.sql`     | PG >= 10      | Tables included in publications     | `pg_publication_rel` |
| Database | `subscription_stats.sql`     | PG >= 10      | Logical replication subscriptions   | `pg_subscription` |
| Database | `subscription_rel_stats.sql` | PG >= 10      | Subscription relations status       | `pg_subscription_rel` |

</details>

<details>
<summary>🔥 Troubleshooting (Emergency & Active Issues)</summary>

| Scope    | Name                                               | Compatibility | Description                                            | Reference |
| :---     | :---                                               | :---:         | :---                                                   | :--- |
| cluster  | `clean_query.sql`                                  |               | Format Query ID showing query without line breaks      | `pg_stat_statements` |
| cluster  | `connections_by_user.sql`                          | PG >= 9.2     | Active connections stats by users                      | `pg_stat_activity` |
| cluster  | `connections_gss.sql`                              | PG >= 12      | Active connections stats using GSSAPI                  | `pg_stat_gssapi` |
| cluster  | `connections_running.sql`                          |               | Active connections stats running now                   | `pg_stat_activity` |
| cluster  | `connections_running_details.sql`                  |               | Detailed active connections stats                      | `pg_stat_activity` |
| cluster  | `connections_ssl.sql`                              | PG >= 9.5     | Active connections stats using SSL                     | `pg_stat_ssl` |
| cluster  | `connections_tot.sql`                              | PG >= 9.2     | Total active connections summary                       | `pg_stat_activity` |
| cluster  | `database_standby_conflicts.sql`                   | PG >= 9.1     | Queries canceled on standby due to conflicts           | `pg_database_conflicts` |
| database | `index_check_btree_integrity.sql`                  | PG >= 10      | Check integrity on every BTREE index                   | `amcheck` |
| database | `index_check_gin_integrity.sql`                    | PG >= 18      | Check integrity on every GIN index                     | `amcheck` |
| database | `index_invalid.sql`                                |               | Indexes marked as invalid                              | `pg_index` |
| database | `kill_active_all_wait_fucking_event.sql`           | PG >= 9.6     | Kill sessions waiting on events (except Client)        | `pg_stat_activity` |
| database | `kill_active_bufferpin.sql`                        | PG >= 9.6     | Kill sessions waiting on "Bufferpin"                   | `pg_stat_activity` |
| database | `kill_active_ipc.sql`                              | PG >= 9.6     | Kill sessions waiting on "IPC"                         | `pg_stat_activity` |
| database | `kill_active_lwlock.sql`                           | PG >= 9.6     | Kill sessions waiting on "LWLock"                      | `pg_stat_activity` |
| database | `kill_active_io_query_time_greater_10_seconds.sql` | PG >= 9.6     | Kill active sessions running > 10s and waiting on "IO" | `pg_stat_activity` |
| database | `kill_active_io_query_time_greater_60_seconds.sql` | PG >= 9.6     | Kill active sessions running > 60s and waiting on "IO" | `pg_stat_activity` |
| database | `kill_active_query_time_greater_10_seconds.sql`    |               | Kill sessions running for more than 10 seconds         | `pg_stat_activity` |
| database | `kill_active_query_time_greater_60_seconds.sql`    |               | Kill sessions running for more than 60 seconds         | `pg_stat_activity` |
| database | `kill_idle_greater_10_minutes.sql`                 |               | Kill idle sessions running for more than 10 minutes    | `pg_stat_activity` |
| database | `kill_idle_greater_60_minutes.sql`                 |               | Kill idle sessions running for more than 60 minutes    | `pg_stat_activity` |
| database | `kill_idle_in_transaction_60_seconds.sql`          |               | Kill idle in transaction sessions > 60 seconds         | `pg_stat_activity` |
| database | `kill_oldest_blocker.sql`                          | PG >= 9.6     | Kill oldest locker session                             | `pg_blocking_pids()` |
| cluster  | `locks.sql`                                        | PG >= 8.3     | Current locks and blockers                             | `pg_locks` |
| cluster  | `pgbouncer_fdw.sql`                                |               | Create views for pgBouncer SHOW commands               | `dblink` extension |
| cluster  | `prepared_transactions.sql`                        |               | Current prepared transactions                          | `pg_prepared_xacts` |
| cluster  | `progress_analyze.sql`                             | PG >= 13      | Status about ANALYZE commands running                  | `pg_stat_progress_analyze` |
| cluster  | `progress_basebackup.sql`                          | PG >= 13      | Status about pg_basebackup running                     | `pg_stat_progress_basebackup` |
| cluster  | `progress_cluster.sql`                             | PG >= 12      | Status about CLUSTER commands running                  | `pg_stat_progress_cluster` |
| cluster  | `progress_copy.sql`                                | PG >= 14      | Status about COPY commands running                     | `pg_stat_progress_copy` |
| cluster  | `progress_index.sql`                               | PG >= 12      | Status about CREATE INDEX commands running             | `pg_stat_progress_create_index` |
| cluster  | `progress_vacuum.sql`                              | PG >= 9.6     | Status about VACUUM commands running                   | `pg_stat_progress_vacuum` |

</details>

<details>
<summary>⚙️ Tuning (Object & Parameter Optimization)</summary>

| Scope    | Name                                   | Compatibility | Description                                  | Reference |
| :---     | :---                                   | :---:         | :---                                         | :--- |
| database | `autovacuum_analyze.sql`               |               | List ANALYZE and autovacuum ANALYZE stats    | `pg_stat_user_tables` |
| database | `autovacuum_vacuum_adjust.sql`         | PG >= 8.4     | Recommended scale factor adjustments         | `pg_stat_all_tables` |
| database | `fillfactor.sql`                       | PG >= 8.4     | Tables having more updates and bad HOT ratio | `pg_stat_user_tables` |
| database | `functions.sql`                        | PG >= 8.4     | Functions consuming more execution time      | `pg_stat_user_functions` |
| cluster  | `bgwriter.sql`                         | PG >= 17      | Background Workers stats                     | `pg_stat_bgwriter` |
| cluster  | `checkpoints.sql`                      | PG >= 8.3     | Checkpoint stats                             | `pg_stat_checkpointer` |
| cluster  | `wal.sql`                              | PG >= 14      | Transaction logs (WAL) statistics            | `pg_stat_wal` |
| database | `shared_buffers_stats.sql`             | PG >= 13      | Shared buffer usage per database             | `pg_buffercache` |

</details>

<details>
<summary>⚡ Query Tuning (SQL Performance)</summary>

| Scope    | Name                                   | Compatibility | Description                                                           | Reference |
| :---     | :---                                   | :---:         | :---                                                                  | :--- |
| Database | `io_index.sql`                         | PG >= 8.4     | I/O stats for indexes                                                 | `pg_statio_all_indexes` |
| Database | `io_sequence.sql`                      | PG >= 8.4     | I/O stats for sequences                                               | `pg_statio_all_sequences` |
| Database | `io_table_heap.sql`                    | PG >= 8.4     | I/O stats for heap on tables                                          | `pg_statio_all_tables` |
| Database | `io_table_index.sql`                   | PG >= 9.1     | I/O stats for indexes on tables                                       | `pg_statio_all_tables` |
| Database | `io_table_others.sql`                  | PG >= 9.1     | I/O stats for TOAST and TID on tables                                 | `pg_statio_all_tables` |
| Cluster  | `statements_group_database_resume.sql` | PG >= 14      | total statements for each database on cluster order by execution time | `pg_stat_statements` |
| Cluster  | `statements_group_database_temp.sql`   | PG >= 9.2     | top 10 statements on all cluster order by temporary files             | `pg_stat_statements` |
| Cluster  | `statements_group_database_time.sql`   | PG >= 9.4     | top 10 statements on all cluster order by execution time              | `pg_stat_statements` |
| Cluster  | `statements_group_database_total.sql`  | PG >= 14      | total statements for each database on cluster                         | `pg_stat_statements` |
| Database | `statements_calls.sql`                 | PG >= 8.4     | top 10 statements order by calls                                      | `pg_stat_statements` |
| Database | `statements_jit.sql`                   | PG >= 15      | top 10 statements order by jit calls                                  | `pg_stat_statements` |
| Database | `statements_local.sql`                 | PG >= 9.2     | top 10 statements order by local memory used                          | `pg_stat_statements` |
| Database | `statements_plan.sql`                  | PG >= 14      | top 10 statements planing time                                        | `pg_stat_statements` |
| Database | `statements_resume.sql`                | PG >= 14      | top 20 statements order by planing and execution time                 | `pg_stat_statements` |
| Database | `statements_rows.sql`                  | PG >= 8.4     | top 10 statements order by rows                                       | `pg_stat_statements` |
| Database | `statements_rows_call.sql`             | PG >= 8.4     | top 10 statements statistics order by rows per call                   | `pg_stat_statements` |
| Database | `statements_shared.sql`                | PG >= 9.2     | top 10 statements order by shared memory on disk used                 | `pg_stat_statements` |
| Database | `statements_temp.sql`                  | PG >= 9.2     | top 10 statements order by temporary files                            | `pg_stat_statements` |
| Database | `statements_time.sql`                  | PG >= 8.4     | top 10 statements order by execution time                             | `pg_stat_statements` |
| Database | `statements_top5.sql`                  | PG >= 8.4     | top 5 full query statements order by execution and planing time       | `pg_stat_statements` |
| Database | `statements_total.sql`                 | PG >= 14      | total statements summary                                              | `pg_stat_statements` |
| Database | `statements_wal.sql`                   | PG >= 13      | top 10 statements order by WAL generation                             | `pg_stat_statements` |
| Database | `tables_with_seq_scan.sql`             |               | top 20 tables with more seq scan                                      | `pg_stat_user_tables` |

</details>

<details>
<summary>🛡️ Security (Auditing & Permissions)</summary>

| Scope    | Name                            | Compatibility | Description                                                                     | Reference |
| :---     | :---                            | :---:         | :---                                                                            | :--- |
| Cluster  | `pg_hba.sql`                    | PG >= 10      | pg_hba.conf non-commented lines and errors                                      | List rules even if they are not active yet after any change on `pg_hba.conf` file |
| Cluster  | `backup.sql`                    | PG >= 9.1     | Look for a `.backup` file with physical backup summary at `pg_wal` or `pg_xlog` | `pg_read_file()` and `pg_ls_dir` functions |
| Cluster  | `user_priv.sql`                 |               | Roles with high privileges options like superusers                              | `pg_roles`       |
| Cluster  | `user_granted_roles.sql`        |               | Granted roles to other roles                                                    | `pg_auth_members` |
| Database | `object_privileges_list.sql`    |               | Privileges on objects                                                           | `pg_class`, `pg_roles` |
| Database | `security_policies.sql`         | PG >= 9.5     | Policies for Row Level Security                                                 | `pg_policies` |
| Database | `user_default_privileges.sql`   | PG >= 9.0     | Default privileges                                                              | `pg_default_acl` |
| Database | `user_granted_parameters.sql`   | PG >= 15      | Privileges on parameters                                                        | `pg_parameter_acl` |
| Database | `user_owners_x_connections.sql` |               | Current number of connections and objects owned by each role                    | `pg_stat_activity`, `pg_class` |

</details>

---

## 🐚 Shell Scripts

In addition to SQL scripts, this repository provides shell utilities for OS-level tuning and report generation.

| Name              | Description                                                                                                                           |
| :---              | :---                                                                                                                                  |
| `ajustes_so.sh`   | A comprehensive guide and script for Linux kernel tuning (sysctl, huge pages, transparent huge pages, etc.) optimized for PostgreSQL. |
| `report_so.sh`    | Generates a complete Markdown report of the Operating System (CPU, Memory, Network, Disks, and Kernel parameters).                    |
| `exec_comando.sh` | A wrapper script to execute a SQL command (defined in `comando.sql`) across all databases in the cluster.                             |

---

## ⚠️ Safety & Best Practices

Before running these scripts in a production environment, please consider the following:

> [!WARNING]
> **Use at your own risk:** These scripts are provided as-is. Always test them in a staging or development environment before executing them in production.

- **Performance Overhead:** Some scripts, particularly those calculating **Bloat** or **Table Sizes**, may perform sequential scans or heavy meta-data lookups. On very large databases, this can cause temporary performance degradation.
- **Transaction Locks:** While most scripts are read-only (SELECT), monitoring long-running transactions or locks is critical. Avoid running scripts that create temporary tables during peak hours if your disk I/O is near its limit.
- **Read-Only Intent:** All scripts in this repository are designed for **read-only** diagnostic purposes. They do not perform `DROP`, `DELETE`, or `TRUNCATE` operations. However, always verify the script content before execution.

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to add new scripts or improve existing ones.

---
*Maintained with ❤️ by the PostgreSQL community.*
