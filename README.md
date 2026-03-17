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

- [x] **PostgreSQL 8.2+**: While most scripts work PostgreSQL 8.2 to the current version (PostgreSQL 18 now). Unfortunately some of them will not work on older versions because some features did not exist on them.
- [x] **psql** client: The standard PostgreSQL command-line tool. Most of thise scripts use meta-commands from psql to format output or to choose the correct version of PostgreSQL you are running. Of course you can take the SQL script manually and run in any PostgreSQL compatible client.
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

| Scope    | Name                              | Compatibility | Description                                   | Reference |
| :---     | :---                              | :---: 		   | :---                                          | :---      |
| Cluster  | `archives.sql`                    | PG >= 9.4 	   | Amount of WAL archives generated              | [`pg_stat_archiver`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ARCHIVER-VIEW) |
| Database | `extensions.sql`                  | PG >= 9.0     | List all installed extensions                 | [`pg_extension`](https://www.postgresql.org/docs/current/catalog-pg-extension.html) |
| Database | `index_big.sql`                   |               | Indexes > 800KB and > 50% of table size       | [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html) |
| Database | `index_functions.sql`             |               | Indexes using expressions on columns          | [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html) |
| Cluster  | `database_size.sql`               |               | Databases on cluster: size and options        | [`pg_database`](https://www.postgresql.org/docs/current/catalog-pg-database.html) |
| Database | `index_non_btree.sql`             |               | Non-BTREE indexes                             | [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html), [`pg_am`](https://www.postgresql.org/docs/current/catalog-pg-am.html) |
| Database | `index_non_default_collation.sql` | PG >= 9.1     | Indexes without default collation             | [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html), [`pg_collation`](https://www.postgresql.org/docs/current/catalog-pg-collation.html) |
| Database | `index_partial.sql`               |               | Partial indexes                               | [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html) |
| Database | `index_size.sql`                  | PG >= 8.3     | Top 20 indexes by size                        | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html), [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html) |
| Cluster  | `internal.sql`                    |               | Cluster parameters and internal stats         | [`current_setting()`](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-SET-TABLE) function |
| Cluster  | `io_cluster.sql`                  | PG >= 16      | Cluster-wide I/O statistics                   | [`pg_stat_io`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-IO-VIEW) |
| Database | `materialized_views.sql`          | PG >= 9.3     | Materialized views inventory                  | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html) |
| Database | `object_size.sql`                 |               | Top 20 objects by size                        | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html) |
| Cluster  | `pg_config.sql`                   | PG >= 9.6     | Compilation and build parameters              | [`pg_config`](https://www.postgresql.org/docs/current/app-pgconfig.html) |
| Database | `schemas.sql`                     |               | Schema inventory                              | [`pg_namespace`](https://www.postgresql.org/docs/current/catalog-pg-namespace.html) |
| Database | `tables_changes.sql`              |               | Top 10 tables with most I/U/D activity        | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW) |
| Database | `tables_delete.sql`               |               | Top 10 tables with more DELETEs               | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW) |
| Database | `tables_fks.sql`                  | PG >= 9.5     | Table precedence based on FK inheritance      | [`pg_constraint`](https://www.postgresql.org/docs/current/catalog-pg-constraint.html) |
| Database | `tables_foreign.sql`              | PG >= 9.1     | Foreign Tables using FDW                      | [`pg_foreign_table`](https://www.postgresql.org/docs/current/catalog-pg-foreign-table.html) |
| Database | `tables_insert.sql`               |               | Top 10 tables with more INSERTs               | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW) |
| Database | `tables_partition.sql`            | PG >= 12      | Partitioned tables and indexes                | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html), [`pg_inherits`](https://www.postgresql.org/docs/current/catalog-pg-inherits.html) |
| Database | `tables_rule.sql`                 |               | Tables with rules defined                     | [`pg_rules`](https://www.postgresql.org/docs/current/view-pg-rules.html) |
| Database | `tables_size.sql`                 | PG >= 9.5     | Top 20 tables by size                         | [`pg_table_size()`](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-DBOBJECT) function |
| Database | `tables_unlogged.sql`             | PG >= 9.3     | List of unlogged tables                       | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html) |
| Database | `tables_update.sql`               |               | Top 10 tables with more UPDATEs               | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW) |
| Database | `tablespaces.sql`                 |               | Tablespace inventory                          | [`pg_tablespace`](https://www.postgresql.org/docs/current/catalog-pg-tablespace.html) |
| Database | `tablespace_objects.sql`          | PG >= 9.4     | Number of objects by type for each tablespace | [`pg_tablespace`](https://www.postgresql.org/docs/current/catalog-pg-tablespace.html) |
| Database | `trigger_events.sql`              | PG >= 9.3     | Event Triggers                                | [`pg_event_trigger`](https://www.postgresql.org/docs/current/catalog-pg-event-trigger.html) |
| Database | `trigger_tables.sql`              |               | Table Triggers                                | [`pg_trigger`](https://www.postgresql.org/docs/current/catalog-pg-trigger.html), [`pg_proc`](https://www.postgresql.org/docs/current/catalog-pg-proc.html) |
| Database | `views.sql`                       |               | View inventory                                | [`pg_views`](https://www.postgresql.org/docs/current/view-pg-views.html) |

</details>

<details>
<summary>🛠️ Maintenance (Optimization & Cleanup)</summary>

| Scope    | Name                                    | Compatibility | Description                                                                                              | Reference                                                                                                                                                             | Comments |
| :---     | :---                                    | :---:         | :---                                                                                                     | :---                                                                                                                                                                  | :--- |
| Database | `index_dup.sql`                         |               | Duplicated indexes that have same columns                                                                | [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html)                                                                                           |  We recommend checking manually other differences before dropping any index | |
| Database | `index_missing_in_fk.sql`               | PG >= 9.4     | Foreign Keys without an associated index on same columns                                                 | [`pg_constraint`](https://www.postgresql.org/docs/current/catalog-pg-constraint.html) and [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html) | |
| Database | `index_missing_in_fk_create.sql`        | PG >= 9.4     | CREATE INDEX command for every Foreign Keys without an associated index on same columns                  | [`pg_constraint`](https://www.postgresql.org/docs/current/catalog-pg-constraint.html) and [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html) | |
| Database | `index_poor.sql`                        | PG >= 8.4     | Indexes with bad performance based on some criteria                                                      | [`pg_stat_user_indexes`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-INDEXES-VIEW)                                           | We advise that this list doesn't include other replicas that may use these indexes |
| Database | `index_poor_drop.sql`                   |               | DROP INDEX command for every not used index                                                              | [`pg_stat_user_indexes`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-INDEXES-VIEW)                                           | We advise that this list doesn't include other replicas that may use these indexes |
| Database | `index_stat_btree.sql`                  | PG >= 8.3     | Top 20 BTREE indexes that may need a REINDEX (vg_leaf_density <= 70 OR leaf_fragmentation >= 20) by size | [`pgstatindex(oid)`](https://www.postgresql.org/docs/current/pgstattuple.html) function                                                                               | Notice that  `pgstatindex(oid)` may take a while to run and overhead your I/O |
| Database | `index_stat_btree_reindex.sql`          | PG >= 10      | Reindex indexes having avg_leaf_density <= 70 OR leaf_fragmentation >= 20                                | [`pgstatindex(oid)`](https://www.postgresql.org/docs/current/pgstattuple.html) function                                                                               | Notice that  `pgstatindex(oid)` may take a while to run and overhead your I/O and REINDEX command will generate I/O overhead and may generate small locks. We advise to monitor server while running this |
| Database | `index_stat_gin.sql`                    | PG >= 9.3     | Statistics about top 20 GIN indexes by size                                                              | [`pgstatginindex(oid)`](https://www.postgresql.org/docs/current/pgstattuple.html) function                                                                            | Notice that  `pgstatginindex(oid)` may take a while to run and overhead your I/O |
| Database | `index_stat_hash.sql`                   | PG >= 10      | Statistics about top 20 HASH indexes by size                                                             | [`pgstathashindex(oid)`](https://www.postgresql.org/docs/current/pgstattuple.html) function                                                                           | Notice that  `pgstathashindex(oid)` may take a while to run and overhead your I/O |
| Database | `index_table_missing.sql`               | PG >= 8.4     | Tables that may need new indexes                                                                         | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)                                             | We advise that this list doesn't include other replicas that may use these indexes |
| Both     | `reset_all_stats.sql`                   | PG >= 9.0     | Reset all stats from current database and cluster                                                        | [`pg_stat_reset_*`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-STATS-FUNCS-TABLE) functions                                                        | This script run an `ANALYZE` command on current database to prevent autovacuum issues |
| Database | `tables_bloat_approx.sql`               | PG >= 8.3     | Top 10 tables with more free space                                                                       | [`pgstattuple_approx()`](https://www.postgresql.org/docs/current/pgstattuple.html) function                                                                           | Notice that `pgstattuple_approx(oid)` may take a while to run and overhead your I/O |
| Database | `tables_index_missing.sql`              | PG >= 8.4     | Tables with poor or few indexes and its reasons                                                          | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)                                             | |
| Database | `tables_not_used.sql`                   | PG >= 8.3     | Tables with low usage                                                                                    | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)                                             | |
| Database | `tables_not_used_drop.sql`              |               | DROP TABLE commands for tables with low usage                                                            | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)                                             | |
| Database | `vacuum_full_or_cluster.sql`            | PG >= 9.5     | VACUUM FULL or CLUSTER commands for tables with more than 20% of free space                              | [`pgstattuple_approx()`](https://www.postgresql.org/docs/current/pgstattuple.html) function                                                                           | Notice that  `pgstattuple_approx(oid)` may take a while to run and overhead your I/O |
| Cluster  | `vacuum_wraparound_database.sql`        |               | Databases near a vacuum wraparound order by age                                                          | [`pg_database`](https://www.postgresql.org/docs/current/catalog-pg-database.html)                                                                                     | |
| Database | `vacuum_wraparound_table.sql`           | PG >= 9.3     | Tables near a vacuum wraparound order by age                                                             | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html)                                                                                           | |
| Database | `vacuum_wraparound_table_clean.sql`     | PG >= 9.5     | VACUUM commands to prevent a vacuum wraparound                                                           | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html)                                                                                           | |
| Database | `vacuum_wraparound_table_multixact.sql` | PG >= 9.5     | Tables near a vacuum wraparound due to multixact age                                                     | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html)                                                                                           | |

</details>

<details>
<summary>🚀 Migration (Upgrades & Logical Replication)</summary>

| Scope    | Name                          | Compatibility | Description                                 | Reference                                                                                                                                                | Comments |  
| :---     | :---                          | :---:         | :---                                        | :---                                                                                                                                                     | :---     |
| Database | `object_privileges_grant.sql` | PG >= 9.3     | Generates GRANT commands for privileges     | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html), [`pg_roles`](https://www.postgresql.org/docs/current/catalog-pg-roles.html) | |
| Database | `reindex_on_new_glibc.sql`    | PG >= 9.1     | REINDEX for collation changes (GLIBC 2.28+) | [`pg_collation`](https://www.postgresql.org/docs/current/catalog-pg-collation.html)                                                                      | |
| Database | `sequence_setval.sql`         |               | Generates setval commands for sequences     | [`nextval()`](https://www.postgresql.org/docs/current/functions-sequence.html) function                                                                  | Useful for logical replicas |
| Database | `tables_with_oid.sql`         | PG < 12       | Identifies tables using deprecated OIDs     | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html)                                                                              | |

</details>

<details>
<summary>🔥 Troubleshooting (Emergency & Active Issues)</summary>

| Scope    | Name                                               | Compatibility | Description                                                                                  | Reference                                                                                                                           |Comments |
| :---     | :---                                               | :---:         | :---                                                                                         | :---                                                                                                                                | :---    |
| Cluster  | `clean_query.sql`                                  |               | Ask for an Query ID and show the query without line breaks and spaces                        | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html)                                               | Only works on psql |
| Cluster  | `connections_by_user.sql`                          | PG >= 9.2     | Active connections stats by users                                                            | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Cluster  | `connections_gss.sql`                              | PG >= 12      | Active connections stats using GSSAPI  authentication                                        | [`pg_stat_gssapi`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-GSSAPI-VIEW)                    | |
| Cluster  | `connections_running.sql`                          |               | Active connections stats running now                                                         | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Cluster  | `connections_running_details.sql`                  |               | Active detailed connections stats running now                                                | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Cluster  | `connections_ssl.sql`                              | PG >= 9.5     | Active connections stats using SSL                                                           | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Cluster  | `connections_tot.sql`                              | PG >= 9.2     | Total active connections stats running now                                                   | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Cluster  | `database_standby_conflicts.sql`                   | PG >= 9.1     | Queries canceled on standby due to conflicts with master                                     | [`pg_database_conflicts`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-DATABASE-CONFLICTS-VIEW) | |
| Database | `index_check_btree_integrity.sql`                  | PG >= 10      | Check integrity on every BTREE index                                                         | [`bt_index_check(oid)`](https://www.postgresql.org/docs/current/amcheck.html#AMCHECK-FUNCTIONS) function                            | |
| Database | `index_check_gin_integrity.sql`                    | PG >= 18      | Check integrity on every GIN index                                                           | [`gin_index_check(oid)`](https://www.postgresql.org/docs/current/amcheck.html#AMCHECK-FUNCTIONS) function                           | |
| Database | `index_invalid.sql`                                |               | Indexes marked as invalid                                                                    | [`pg_index`](https://www.postgresql.org/docs/current/catalog-pg-index.html)                                                         | |
| Database | `kill_active_all_wait_fucking_event.sql`           | PG >= 9.6     | Kill active sessions that have any wait event type except "Client"                           | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_active_bufferpin.sql`                        | PG >= 9.6     | Kill active sessions that have wait event type "Bufferpin"                                   | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_active_ipc.sql`                              | PG >= 9.6     | Kill active sessions that have wait event type "IPC"                                         | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_active_lwlock.sql`                           | PG >= 9.6     | Kill active sessions that have wait event type "LWLock"                                      | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_active_io_query_time_greater_10_seconds.sql` | PG >= 9.6     | Kill active sessions that are running for more than 10 seconds and have wait event type "IO" | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_active_io_query_time_greater_60_seconds.sql` |PG >= 9.6      | Kill active sessions that are running for more than 60 seconds and have wait event type "IO" | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_active_query_time_greater_10_seconds.sql`    |               | Kill active sessions that are running for more than 10 seconds                               | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_active_query_time_greater_60_seconds.sql`    |               | Kill active sessions that are running for more than 60 seconds                               | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_idle_greater_10_minutes.sql`                 |               | Kill idle sessions that are running for more than 10 minutes                                 | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_idle_greater_60_minutes.sql`                 |               | Kill idle sessions that are running for more than 60 minutes                                 | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_idle_in_transaction_60_seconds.sql`          |               | Kill idle in transaction sessions that are running for more than 60 seconds                  | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)                | |
| Database | `kill_oldest_blocker.sql`                          | PG >= 9.6     | Kill oldest locker session                                                                   | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW) and [`pg_blocking_pids()`](https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-SESSION-TABLE) function | |
| Cluster  | `locks.sql`                                        | PG >= 8.3     | Locks                                                                                        | [`pg_locks`](https://www.postgresql.org/docs/current/view-pg-locks.html), [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW) | | 
| Cluster  | `pgbouncer_fdw.sql`                                |               | Script to create views to pgBouncer virtual database SHOW commands                           | [`dblink`](https://www.postgresql.org/docs/current/dblink.html) extension                                                           | |
| Cluster  | `prepared_transactions.sql`                        |               | Current prepared transactions                                                                | [`pg_prepared_xacts`](https://www.postgresql.org/docs/current/view-pg-prepared-xacts.html)                                          | |
| Cluster  | `progress_analyze.sql`                             | PG >= 13      | Status about ANLYZE commands running                                                         | [`pg_stat_progress_analyze`](https://www.postgresql.org/docs/current/progress-reporting.html#ANALYZE-PROGRESS-REPORTING)            | |
| Cluster  | `progress_basebackup.sql`                          | PG >= 13      | Status about pg_basebackup running                                                           | [`pg_stat_progress_basebackup`](https://www.postgresql.org/docs/current/progress-reporting.html#BASEBACKUP-PROGRESS-REPORTING)      | |
| Cluster  | `progress_cluster.sql`                             | PG >= 12      | Status about CLUSTER commands running                                                        | [`pg_stat_progress_cluster`](https://www.postgresql.org/docs/current/progress-reporting.html#CLUSTER-PROGRESS-REPORTING)            | |
| Cluster  | `progress_copy.sql`                                | PG >= 14      | Status about COPY commands running                                                           | [`pg_stat_progress_copy`](https://www.postgresql.org/docs/current/progress-reporting.html#COPY-PROGRESS-REPORTING)                  | |
| Cluster  | `progress_index.sql`                               | PG >= 12      | Status about CREATE INDEX commands running                                                   | [`pg_stat_progress_create_index`](https://www.postgresql.org/docs/current/progress-reporting.html#CREATE-INDEX-PROGRESS-REPORTING)  | |
| Cluster  | `progress_vacuum.sql`                              | PG >= 9.6     | Status about VACUUM commands running                                                         | [`pg_stat_progress_vacuum`](https://www.postgresql.org/docs/current/progress-reporting.html#VACUUM-PROGRESS-REPORTING)              | |

</details>

<details>
<summary>⚙️ Tuning (Object Optimization)</summary>

| Scope    | Name                             | Compatibility | Description                                                                                                            | Reference                                                                                                                        | Comments | 
| :---     | :---                             | :---:         | :---                                                                                                                   | :---                                                                                                                             | :---     |
| Database | `autovacuum_analyze.sql`         |               | List ANALYZE and autovacuum ANALYZE stats                                                                              | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)        | |
| Database | `autovacuum_analyze_adjust.sql`  |               | Recommend autovacuum_analyze_scale_factor adjust based on number of rows on table                                      | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)        | |
| Database | `autovacuum_vacuum.sql`          | PG >= 8.4     | Top 20 tables with more percentage of dead rows                                                                        | [`pg_stat_all_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)         | |
| Database | `autovacuum_vacuum_+.sql`        | PG >= 9.2     | Top 20 tables with more percentage of dead rows with separate values for toast tables                                  | [`pg_stat_all_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)         | experimental |
| Database | `autovacuum_vacuum_adjust.sql`   | PG >= 8.4     | ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size                                       | [`pg_stat_all_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)         | |
| Database | `autovacuum_vacuum_adjust_+.sql` | PG >= 8.4     | ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size with separate values for toast tables | [`pg_stat_all_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)         | experimental |
| Database | `autovacuum_vacuum_queue.sql`    |               | Next tables on autovacuum vacuum queue                                                                                 | [`pg_stat_all_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)         | |
| Database | `fillfactor.sql`                 | PG >= 8.4     | Tables having more updates and bad hot update ratio                                                                    | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW)        | |
| Database | `functions.sql`                  | PG >= 8.4     | Functions consuming more execution time                                                                                | [`pg_stat_user_functions`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-USER-FUNCTIONS-VIEW) | |
| Database | `object_options.sql`             |               | Objects with options set                                                                                               | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html)                                                      | |
| Database | `tables_alignment_padding.sql`   | PG >= 9.4     | Suggested Columns Reorder                                                                                              |            | |
| Database | `tables_without_index.sql`       |               | Tables without any index                                                                                               | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html)                                                      | |
| Database | `tables_without_pk.sql`          |               | Tables without any Primary Key (PK)                                                                                    | [`pg_constraint`](https://www.postgresql.org/docs/current/catalog-pg-constraint.html)                                            | |

</details>

<details>
<summary>⚙️ Tuning (parameters)</summary>

| Scope    | Name                                    | Compatibility | Description                                                 | Reference |
| :---     | :---                                    | :---:         | :---                                                        | :---      |
| Cluster  | `bgwriter.sql`                          | PG >= 17      | Background Workers stats                                    | [`pg_stat_bgwriter`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-BGWRITER-VIEW) | 
| Database | `autovacuum_queue.sql`                  |               | Next tables where autovacuum will work                      | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW) |
| Cluster  | `checkpoints.sql`                       | PG >= 8.3     | Checkpoint stats                                            | [`pg_stat_checkpointer`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-CHECKPOINTER-VIEW) |
| Cluster  | `conf_directories.sql`                  | PG >= 8.4     | Parameters about file and directories location              | [`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html)|
| Cluster  | `conf_logs.sql`                         |               | Parameters about logs configurations and other related      | [`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html) |
| Cluster  | `conf_master.sql`                       | PG >= 8.4     | Parameters about master server replication configurations   | [`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html) |
| Cluster  | `conf_others.sql`                       | PG >= 8.4     | Other parameters with non default values                    | [`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html) |
| Cluster  | `conf_resource.sql`                     |               | Parameters about resource configuration                     |  [`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html) |
| Cluster  | `conf_recovery.sql`                     | PG >= 8.4     | Parameters about recovery or at recovery.conf file (PG <12) | [`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html) |
| Cluster  | `conf_replica.sql`                      | PG >= 8.4     | Parameters about replication slave                          | [`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html) |
| Database | `database_stats.sql`                    |               | Database stats                                              | [`pg_stat_database`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-DATABASE-VIEW) |
| Cluster  | `ls_logs.sql`                           | PG >= 10      | Logs size                                                   | [`pg_ls_logdir()`](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-GENFILE) function |
| Cluster  | `ls_temp.sql`                           | PG >= 12      | Temporary files size                                        | [`pg_ls_tempdir()`](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-GENFILE) function |
| Cluster  | `ls_wal.sql`                            | PG >= 10      | WAL files size                                              | [`pg_ls_waldir()`](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-GENFILE) function |
| Cluster  | `user_options.sql`                      | PG >= 9.0     | Roles with parameter options set                            | [`pg_db_role_setting`](https://www.postgresql.org/docs/current/catalog-pg-db-role-setting.html)|
| Cluster  | `wal.sql`                               | PG >= 14      | Transaction logs (WAL) statistics                           | [`pg_stat_wal`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-WAL-VIEW) |

</details>

<details>
<summary>⚙️ Tuning (queries)</summary>

| Scope    | Name                                    | Compatibility | Description                                                     | Reference |
| :---     | :---                                    | :---:         | :---                                                            | :---      |
| Database | `io_index.sql`                          | PG >= 8.4     | I/O stats for indexes                                           | [`pg_statio_all_indexes`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STATIO-ALL-INDEXES-VIEW) |
| Database | `io_sequence.sql`                       | PG >= 8.4     | I/O stats for sequences                                         | [`pg_statio_all_sequences`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STATIO-ALL-SEQUENCES-VIEW) |
| Database | `io_table_heap.sql`                     | PG >= 8.4     | I/O stats for heap on tables                                    | [`pg_statio_all_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STATIO-ALL-TABLES-VIEW) |
| Database | `io_table_index.sql`                    | PG >= 9.1     | I/O stats for indexes on tables                                 | [`pg_statio_all_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STATIO-ALL-TABLES-VIEW) |
| Database | `io_table_others.sql`                   | PG >= 9.1     | I/O stats for TOAST and TID on tables                           | [`pg_statio_all_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STATIO-ALL-TABLES-VIEW) |
| Database | `statements_calls.sql`                  | PG >= 8.4     | top 10 statements order by calls                                | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Cluster  | `statements_group_database_resume.sql`  | PG >= 14      | top 10 statements on all cluster order by execution time        | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Cluster  | `statements_group_database_temp.sql`    | PG >= 9.2     | top 10 statements on all cluster order by temporary files       | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Cluster  | `statements_group_database_time.sql`    | PG >= 9.4     | top 10 statements on all cluster order by execution time        | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Cluster  | `statements_group_database_total.sql`   | PG >= 14      | total statements summary on all cluster                         | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_jit.sql`                    | PG >= 15      | top 10 statements order by jit calls                            | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_local.sql`                  | PG >= 9.2     | top 10 statements order by local memory used                    | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_plan.sql`                   | PG >= 14      | top 10 statements planing time                                  | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_resume.sql`                 | PG >= 14      | top 20 statements order by planing and execution time           | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_rows.sql`                   | PG >= 8.4     | top 10 statements order by rows                                 | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_rows_call.sql`              | PG >= 8.4     | top 10 statements statistics order by rows per call             | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_shared.sql`                 | PG >= 9.2     | top 10 statements order by shared memory on disk used           | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_temp.sql`                   | PG >= 9.2     | top 10 statements order by temporary files                      | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_time.sql`                   | PG >= 8.4     | top 10 statements order by execution time                       | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_top5.sql`                   | PG >= 8.4     | top 5 full query statements order by execution and planing time | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_total.sql`                  | PG >= 14      | total statements summary                                        | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `statements_wal.sql`                    | PG >= 13      | top 10 statements order by WAL generation                       | [`pg_stat_statements`](https://www.postgresql.org/docs/current/pgstatstatements.html) extension |
| Database | `tables_with_seq_scan.sql`              |               | top 20 tables with more seq scan                                | [`pg_stat_user_tables`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW) |

</details>

<details>
<summary>🛡️ Security (Auditing & Permissions)</summary>

| Scope    | Name                                    | Compatibility | Description                                                                 | Reference                                                                                                                                                                                                                    | Comments | 
| :---     | :---                                    | :---:         | :---                                                                        | :---                                                                                                                                                                                                                         | :---     |
| Cluster  | `backup.sql`                            | PG >= 9.1     | Look for a `.backup` file with physical backup summary at pg_wal or pg_xlog | [`pg_read_file()`](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-GENFILE) and [`pg_ls_dir()`](https://www.postgresql.org/docs/current/functions-admin.html#FUNCTIONS-ADMIN-GENFILE) functions | | 
| Cluster  | `conf_recovery.sql`                     | PG >= 8.4     | parameters about backup recovery                                            | [`pg_settings`](https://www.postgresql.org/docs/current/view-pg-settings.html)                                                                                                                                               | |
| Cluster  | `connections_gss.sql`                   | PG >= 12      | total connections stats running now using GSS                               | [`pg_stat_gssapi`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-GSSAPI-VIEW)                                                                                                             | |
| Cluster  | `connections_running_ssl.sql`           | PG >= 9.5     | total connections stats running now using SSL                               | [`pg_stat_ssl`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-SSL-VIEW)                                                                                                                   | |
| Database | `object_privileges_list.sql`            |               | privileges on objects                                                       | [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html), [`pg_roles`](https://www.postgresql.org/docs/current/catalog-pg-roles.html)                                                                     | |
| Cluster  | `pg_hba.sql`                            | PG >= 10      | pg_hba.conf non commented lines and errors                                   | [`pg_hba_file_rules`](https://www.postgresql.org/docs/current/view-pg-hba-file-rules.html)                                                                                                                                   | list rules even if they are not active yet after any change on pg_hba.conf file |
| Cluster  | `security_labels.sql`                    | PG >= 9.1     | security labels on SE Linux Security Policies                               | [`pg_seclabels`](https://www.postgresql.org/docs/current/view-pg-seclabels.html)                                                                                                                                             | |
| Database | `security_policies.sql`                 | PG >= 9.5     | policies for Row Level Security                                             | [`pg_policies`](https://www.postgresql.org/docs/current/view-pg-policies.html)                                                                                                                                               | |
| Database | `user_default_privileges.sql`           | PG >= 9.0     | Default privileges                                                          | [`pg_default_acl`](https://www.postgresql.org/docs/current/catalog-pg-default-acl.html)                                                                                                                                      | |
| Database | `user_granted_parameters.sql`           | PG >= 15      | privileges on parameters                                                    | [`pg_parameter_acl`](https://www.postgresql.org/docs/current/catalog-pg-parameter-acl.html)                                                                                                                                  | |
| Cluster  | `user_granted_roles.sql`                |               | granted roles to other roles                                                | [`pg_auth_members`](https://www.postgresql.org/docs/current/catalog-pg-auth-members.html)                                                                                                                                    | |
| Database | `user_owners_x_connections.sql`         |               | current number of connections and objects owned by each role                | [`pg_stat_activity`](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW), [`pg_class`](https://www.postgresql.org/docs/current/catalog-pg-class.html)                            | |
| Cluster  | `user_priv.sql`                         |               | roles with hight privileges options like superusers                         | [`pg_roles`](https://www.postgresql.org/docs/current/catalog-pg-roles.html)                                                                                                                                                  | |

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

- **Be careful using kill scripts on troubleshooting session** : This scripts will kill sessions on current cluster. Be carefull before play with this toys.
- **Performance Overhead:** Some scripts on maintenance session, particularly those calculating **Bloat** or **Table Sizes**, may perform sequential scans or heavy meta-data lookups. On very large databases, this can cause temporary performance degradation. Please see the comments on scripts catalog before run.
- **Read-Only Intent:** All other scripts in this repository are designed for **read-only** diagnostic purposes. They do not perform `DROP`, `DELETE`, or `TRUNCATE` operations. However, always verify the script content before execution.

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to add new scripts or improve existing ones.

