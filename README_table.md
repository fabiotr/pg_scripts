| Type             | Scope    | Name                              | Compatibility | Description                       | Reference                 | Comments |
| :--- | :--- | :--- | :---: | :---  | :--- | :--- |
| assesment        | cluster  | `archives.sql`                    | PG >= 9.4     | Amount of archives generated | `pg_stat_archiver` | | 
| assesment        | cluster  | `backup.sql`                      | PG >= 9.1     | Look for a `.backup` file with physical backup summary at pg_wal or pg_xlog | `pg_pg_read_file()` and `pg_ls_dir` functions | | 
| assesment        | cluster  | `bgwriter.sql`                    | PG >= 17      | Background Workers stats | `pg_stat_bgwriter` | | 
| maintenence      | database | `autovacuum_analyze.sql`          |               | List ANALYZE and autovacum ANALYZE stats | `pg_stat_user_tables` | | 
| maintenance      | database | `autovacuum_analyze_adjust.sql`   |               | Recomend autovacuum_analyze_scale_factor adjust based on number of rows on table | `pg_stat_user_tables` | | 
| maintenance      | database | `autovacuum_queue.sql`            |               | next tables where autovacuum will work | `pg_stat_user_tables` |  |
| maintenance      | database | `autovacuum_vacuum.sql`           | PG >= 8.4     | top 20 tables with more percentage of dead rows | `pg_stat_all_tables` | |
| maintenance      | database | `autovacuum_vacuum_+.sql`         | PG >= 9.2     | top 20 tables with more percentage of dead rows with separate values for toast tables | `pg_stat_all_tables`| experimental |
| maintenance      | database | `autovacuum_vacuum_adjust.sql`    | PG >= 8.4     | ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size | Based on `pg_stat_all_tables` |
| maintenance      | database | `autovacuum_vacuum_adjust_+.sql`  | PG >= 8.4     | ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size with separate values for toast tables | `pg_stat_all_tables` | experimental |
| assesment        | cluster  | `checkpoints.sql`                 | PG >= 8.3     | checkpoint stats | `pg_stat_checkpointer` |  |
| assesment        | cluster  | `conf_directories.sql`            | PG >= 8.4     | parameteres about file and directories location | `pg_settings`| |
| assesment        | cluster  | `conf_logs.sql`                   |               | parameters about logs configurations and other related | `pg_settings` | |
| assesment        | cluster  | `conf_master.sql`                 | PG >= 8.4     | parameters abous master server replication | `pg_settings` | | 
| assesment        | cluster  | `conf_others.sql`                 | PG >= 8.4     | other parameters with non default values | `pg_settings` | | 
| assesment        | cluster  | `conf_recovery.sql`               | PG >= 8.4     | parameters about backup recovery | Based on `pg_settings` | |
| assesment        | cluster  | `conf_replica.sql`                | PG >= 8.4     | parameters about slave server replication | `pg_settings` | | 
| assesment        | cluster  | `conf_resource.sql`               |               | parameters about resource configuration |  `pg_settings` | | 
| assesment        | cluster  | `connections_gss.sql`             | PG >= 12      | total connections stats runing now using GSS |   `pg_stat_gssapi` | |
| troubleshooting  | cluster  | `connections_runing.sql`          |               | active connections stats runing now | Based on `pg_stat_activity` | |
| troubleshooting  | cluster  | `connections_runing_detais.sql`   |               | active detailed connections stats runing now | `pg_stat_activity` | |
| assesment        | cluster  | `connections_runing_ssl.sql`      | PG >= 9.5     | total connections stats running now using SSL | `pg_stat_ssl` | |
| troubleshooting  | cluster  | `connections_tot.sql`             | PG >= 9.2     | total active connections stats running now | `pg_stat_activity` | |
| assesment        | cluster  | `database_size.sql`               |               | databases on cluster, size and options | `pg_database` | |
| troubleshooting  | cluster  | `database_standby_conflicts.sql`  | PG >= 9.1     | queries canceled on standby due to conflicts with master | `pg_database_conflicts` | |
| assesment        | database | `database_stats.sql`              |               | database stats | `pg_stat_database` | |
| maintenance      | database | `fillfactor.sql`                  | PG >= 8.4     | tables having more updates and bad hot update ratio | `pg_stat_user_tables` | |
| assesment        | database | `functions.sql`                   | PG >= 8.4     | functions consuming more execution time | `pg_stat_user_functions` | |
| assesment        | database | `index_big.sql`                   |               | indexes greater than 800KB and greater than 50% of table size | `pg_index` | |
| troubleshooting  | database | `index_check_btree_integrity.sql` | PG >= 10      | check integrity on every BTREE index | | `bt_index_check(oid)` function on `amcheck` extension | | 
| troubleshooting  | database | `index_check_gin_integrity.sql`   | PG >= 18      | check integrity on every GIN index | `bt_index_check(oid)` function on `amcheck` extension | |
| maintenance      | database | `index_dup.sql`                   |               | duplicated indexes that have same columns | `pg_index` |  We recommend check manually other differences before drop any index | |
| assesment        | database | `index_functions.sql`             |               | indexes having expressions on columns | `pg_index` | |
| troubleshooting  | database | `index_invalid.sql`               |               | indexes marked as invalid | `pg_index` | |
| maintenance      | database | `index_missing_in_fk.sql`         | PG >= 9.4     | Foreign Keys without an associated index on same columns | `pg_constraint` and `pg_index` | | 
| maintenance      | database | `index_missing_in_fk_create.sql`  | PG >= 9.4     | CREATE INDEX command for every Foreign Keys whithout an associated index on same columns | `pg_constraint` and `pg_index` | |
| assesment        | database | `index_non_btree.sql`             |               | indexes non BTREE | `pg_index` and `pg_am` | |
| assesment        | database | `index_non_default_collation.sql` | PG >= 9.1     | indexes whithout default collation | `pg_index` and `pg_collation` | |
| assesment        | database | `index_partial.sql`               |               | partial indexes | `pg_index` | |
| maintenance      | database | `index_poor.sql`                  | PG >= 8.4     | indexes with bad performance based on some criterias | `pg_stat_user_indexes` | We advise that this list don''d include other replicas that may use this indexes |
| maintenance      | database | `index_poor_drop.sql`             |               | DROP INDEX command for every not used index | `pg_stat_user_indexes` | We advise that this list don''d include other replicas that may use this indexes |
| assesment        | database | `index_size.sql`                  | PG >= 8.3     | top 20 indexes by size | `pg_class`, `pg_index` | | 
| maintenance      | database | `index_stat_btree.sql`            | PG >= 8.3     | top 20 BTREE indexes that may need a REINDEX (having avg_leaf_density <= 70 OR leaf_fragmentation >= 20) ordered by index size | `pgstatindex(oid)` function on `pgstattuble` extension | Notice that  pgstatindex(oid) may take a wile to run and overhead your I/O |
| maintenance      | database | `index_stat_gin.sql`              | PG >= 9.3     | statistics about top 20 GIN indexes by size | `pgstginatindex(oid)` function on `pgstattuble` extension | Notice that  pgstatginindex(oid) may take a wile to run and overhead your I/O |
| maintenance      | database | `index_stat_hash.sql`             | PG >= 10      | statistics about top 20 HASH indexes by size | `pgstathashindex(oid)` function on `pgstattuble` extension | Notice that  pgstathashindex(oid) may take a wile to run and overhead your I/O |
| assesment        | cluster  | `internal.sql`                    |               | some cluster parameters and stats | `current_setting` function | | 
| assesment        | cluster  | `io_cluster.sql`                  | PG >= 16      | I/O stats | `pg_stat_io` | |
| assesment        | database | `io_index.sql`                    | PG >= 8.4     | I/O stats for indexes | `pg_statio_all_indexes` | |
| assesment        | database | `io_sequence.sql`                 | PG >= 8.4     | I/O stats for sequences | `pg_statio_all_sequences` | |
| assesment        | database | `io_table_heap.sql`               | PG >= 8.4     | I/O stats for heap on tables | `pg_statio_all_tables` | |
| assesment        | database | `io_table_index.sql`              | PG >= 9.1     | I/O stats for indexes on tables | `pg_staio_all_tables` | |
| assesment        | database | `io_table_others.sql`             | PG >= 9.1     | I/O stats for TOAST and TID on tables | `pg_statio_all_tables` | | 
| troubleshooting  | cluster  | `locks.sql`                       | PG >= 8.3     | Locks | `pg_locks`, `pg_stat_activity` | | 
| assesment        | cluseter | `ls_logs.sql`                     | PG >= 10      | logs size | `pg_ls_logdir()` function | |
| assesment        | cluster  | `ls_temp.sql`                     | PG >= 12      | temporary files size | `pg_ls_tempdir()` function | | 
| assesment        | cluster  | `ls_wal.sql`                      | PG >= 10      | wal files size | `pg_ls_waldir()` function | |
| assesment        | database | `materialized_views.sql`          | PG >= 9.3     | materialized views | `pg_class` | |
| assesment        | database | `object_options.sql`              |               | objects with options set | `pg_class` | |
| assesment        | database | `object_privileges_list.sql`      |               | privileges on objects | `pg_class`, `pg_roles` | |
| migration        | database | `object_privileges_grant.sql`     | PG >= 9.3     | GRANT command for every object privilege | `pg_class`, `pg_roles` | |
| assesment        | database | `object_size.sql`                 |               | top 20 objects by size | `pg_class` | | 
| assesment        | cluster  | `pg_config.sql`                   | PG >= 9.6     | compilation parameters | | `pg_config` | |
| assesment        | cluster  | `pg_hba.sql`                      | PG >= 10      | pg_hba.conf non commented lines and erros | `pg_hba_file_rules` | list rules even if they are not active yet after any change on pg_hba.conf file | 
| troubleshooting  | cluster  | `pgbouncer_fdw.sql`               |               | Script to create viws to pgbouncer virtual database SHOW commands | `dblink` extension | | 
| troubleshooting  | cluster  | `prepared_transactions.sql`       |               | current prepared transactions | `pg_prepared_xacts` | | 
| troubleshooting  | cluster  | `progress_analyze.sql`            | PG >= 13      | status about ANLYZE commands running | `pg_stat_progress_analyze` | |
| troubleshooting  | cluster  | `progress_basebackup.sql`         | PG >= 13      | status about pg_basebackup running | `pg_stat_progress_basebackup` | |
| troubleshooting  | cluster  | `progress_cluster.sql`            | PG >= 12      | status about CLUSTER commands running | `pg_stat_progress_cluster` | |
| troubleshooting  | cluster  | `progress_copy.sql`               | PG >= 14      | status about COPY commands running | `pg_stat_progress_copy` | |
| troubleshooting  | cluster  | `progress_index.sql`              | PG >= 12      | status about CREATE INDEX commands running | `pg_stat_progress_create_index` | |
| troubleshooting  | cluster  | `progress_vacuum.sql`             | PG >= 9.6     | status about VACUUM commands running | `pg_stat_progress_vacuum` | |
| assesment        | database | `publication_schemas.sql`         | PG >= 15      | publications on schemas | `pg_publication_namespace` | |
| assesment        | database | `publication_tables.sql`          | PG >= 12      | publications on tables | `pg_publication_tables` | | 
| assesment        | database | `publications.sql`                | PG >= 10      | publications | `pg_publication` | |
| migration        | database | `reindex_on_new_glibc.sql`        | PG >= 9.1     | REINDEX commands to recreate index on varchar and text data types | `pg_collation`, `pg_index` | Use when migrate from a Linux server with GLIBC < 2.28 to a Linux server with GLIBC >= 2.28 |
| assesment        | cluster  | `replication_origin.sql`          | PG >= 9.5     | replication origins created and associated status if exists | `pg_replication_origin`, `pg_replication_origin_status` | 
| troubleshooting  | cluster  | `replication_slots.sql`           | PG >= 9.5     | replication slots | `pg_replication_slots` | |
| troubleshooting  | cluster  | `replication_stats.sql`           | PG >= 9.5     | replication stats on master | `pg_stat_replication` | |
| migration        | database | `revoke_from_pg_catalog_functions.sql` | PG >= 9.1 and PG < 12 | REVOKE commands on functions using deprecated data types abstime, reltime and tinterval | `pg_proc` | used to avoid erros when migrating to PG >= 12 | 
| migration        | cluster  | `role_migrate_paas.sql`           | PG >= 8.4     | Help to migrate roles from a PaaS ou DBaaS (as AWS RDS) where you can't access pg_athid and it's passwords | `pg_roles` | This script is deprecated since PG >= 10, where you can use pg_dumpall --no-role-passwords instead |
| assesment        | database | `schemas.sql`                     |               | schemas | `pg_namespaces` | |

### security_labes.sql
- Works on PG >= 9.1
- Show all security labels on SE Linux Security Policies
- Based on pg_seclabels
### security_policies.sql
- Works on PG >= 9.5
- Show all policies for Row Level Security
- Based on pg_policies
### sequence_setval.sql
- Help to set sequences values when setting a new logical replica for all tables on database
- Based on pg_class
### shared_buffers_stats.sql
- Works on PG >= 13
- Show current shared_buffers statistics
- Based on pg_shmen_allocations
### slru_stats.sql
- Works on PG >= 13
- Show slru statustics
- Based on pg_stat_slru
### statements_calls.sql
- Works on PG >= 8.4
- Show top 10 statements statistics on current database order by calls
- Based on pg_stat_statements extension
### statements_group_database_temp.sql
- Works on PG >= 9.2
- Show top 10 statements statistics grouped by database an roles order by temporary files
- Based on pg_stat_statements extension
### statements_group_database_time.sql
- Works on PG >= 9.4
- Show top 10 statements statistics grouped by database and roles order by execution time
- Based on pg_stat_statements extension
### statements_jit.sql
- Works on PG >= 15
- Show top 10 statements statistics on current database order by jit calls
- Based on pg_stat_statements extension
### statements_local.sql
- Works on PG >= 9.2
- Show top 10 statements statistics on current database order by local memmory used
- Based on pg_stat_statements extension
### statements_plan.sql
- Works on PG >= 14
- Show top 10 statements statistics on current database order by planing time
- Based on pg_stat_statements extension
### statements_resume.sql
- Works on PG >= 14
- Show top 20 statements statistics on current database order by planing and execution time
- Based on pg_stat_statements extension
### statements_rows.sql
- Works on PG >= 8.4
- Show top 10 statements statistics on current database order by rows
- Based on pg_stat_statements extension
### statements_rows_call.sql
- Works on PG >= 8.4
- Show top 10 statements statistics on current database order by rows per call
- Based on pg_stat_statements extension
### statements_shared.sql
- Works on PG >= 9.2
- Show top 10 statements statistics on current database order by shared memmory on disk used
- Based on pg_stat_statements extension
### statements_temp.sql
- Works on PG >= 9.2
- Show top 10 statements statistics on current database order by temporary files
- Based on pg_stat_statements extension
### statements_time.sql
- Works on PG >= 8.4
- Show top 10 statements statistics on current database order by execution time
- Based on pg_stat_statements extension
### statements_top5.sql
- Works on PG >= 8.4
- Show top 5 full query statements statistics on current database order by execution and planing time
- Based on pg_stat_statements extension
### statements_total.sql
- Works on PG >= 14
- Show total statements summary statistics on current database
- Based on pg_stat_statements extension
### statements_wal.sql
- Works on PG >= 13
- Show top 10 statements statistics on current database order by execution and WAL generation
- Based on pg_stat_statements extension
### subscription_rel_stats.sql
- Works on PG >= 10
- Show tables logical replication stats from subscription
- Based on pg_subscripton_rel
### subscription_stats.sql
- Works on PG >= 10
- Show logical replication stats from subscriptions
- Based on pg_stat_subscription and pg_stat_subscription_stats
### tables_alignment_padding.sql
- Works on PG >= 94
- Suggested Columns Reorder
### tables_bloat_approx.sql
- Works on PG >= 8.3
- Show top 10 tables with more free size that may need maintenance
- Based on pgstattuple_aprrox() function on pgstattuple extension
- - Notice that  pgstattuple(oid) may take a wile to run and overhead your I/O
### tables_changes.sql
- Show top 10 tables with more INSERTs, UPDATEs and DELETEs
- Based on pg_stat_user_tables
### tables_delete.sql
- Show top 10 tables with more DELETEs
### tables_fks.sql
- Works on PG >= 95
- Show tables precedence based on FK inheritance
- Based on pg_class and pg_constraint
### tables_foreign.sql
- Works on PG >= 9.1
- Show Foreign Tables usind FDW
- Based on pg_foreign_table
### tables_index_missing.sql
- Works on PG >= 8.4
- Show tables with poor or few indexes and its reasons
- Based on pg_stat_user_tables
### tables_insert.sql
- Show top 10 tables with more INSERTs
- Based on pg_stat_user_tables
### tables_not_used.sql
- Works on PG >= 8.3
- Show Tables with low usage
- Based on pg_stat_user_tables
### tables_not_used_drop.sql
- Show DROP TABLE commant for tables with low usage
- Based on pg_stat_user_tables
### tables_partition.sql
- Works on PG >= 12
- Show partitined objects (tables and indexes)
- Based on pg_class and pg_inherits
### tables_pk_default_values.sql
- Works on PG >= 9.0
- Show tables with their Primary Keys (PKs) and it's default values
- Based on pg_class, pg_constraint and pg_atrribute
### tables_rule.sql
- Show tables with rules
- Based on pg_rules
### tables_size.sql
- Works on PG >= 9.5
- Show top 20 tables by size and it's free space
- Based on pgstattuple_approx() function on pgstattuple extension
- Notice that  pgstatituple_approx(oid) may take a wile to run and overhead your I/O
### tables_uk_default_values.sql
- Works on PG >= 9.0
- Show tables with Unique Key (UK) and it's default values
- Based on pg_class, pg_constraint and pg_atrribute
### tables_unlogged.sql
- Works on PG >= 9.3
- Show unlogged tables
- Based on pg_class
### tables_update.sql
- Show top 10 tables with more UPDATEs
- Based on pg_stat_user_tables
### tables_with_oid.sql
- Works on PG < 12
- Show user tables with OIDs that become deprecated on PG 12
- Based on pg_class
### tables_with_seq_scan.sql
- Show top 20 tables with more seq scan
- Based on pg_stat_user_tables
### tables_without_index.sql
- Show tables without any index
- Based on pg_class
### tables_without_pk.sql
- Show tables without any Primary Key (PK)
- Based on pg_class and pg_constraint
### tablespaces.sql
- Show current tablespaces
- Based on pg_tablespace
### tablespace_objects.sql
- Works on PG >= 9.4
- Show the number of objects by type for each tablespace
- Based on pg_class and pg_tablespace
### trigger_events.sql
- Works on PG >= 9.3
- Show existing Event Triggers
- Based on pg_event_trigger
### trigger_tables.sql
- Show Table Triggers
- Based on pg_trigger, pg_class and pg_proc
### user_default_privileges.sql
- Works on PG >= 9.0
- Show Default privileges on current database
- Based on pg_default_acl
### user_granted_parameters.sql
- Works on PG >= 15
- Show privileges on parameters
- Based on pg_parameter_acl
### user_granted_roles.sql
- Show granted roles to other roles
- Based on pg_auth_members
### user_options.sql
- Works on PG >= 9.0
- Show roles with parameter options set
- Based on pg_db_role_setting
### user_owners_x_connections.sql
- Show the current number of connections and objets owned by each role.
- Based on pg_stat_activity and pg_class
### user_priv.sql
- Show users with hight privileges like superusers
- Based on pg_roles
### vacuum_full_or_cluster.sql
- Works on PG >= 9.5
- Show VACUUM FULL or CLUSTER commands for tables with more than 20% of free space
- Based on pgstattuple_approx() function on pgstattuple extension
- Notice that  pgstattuple_approx(oid) may take a wile to run and overhead your I/O
### vacuum_wraparound_database.sql
- Show databases near a vacuum wraparound order by age
- Based on pg_database
### vacuum_wraparound_table.sql
- Works on PG >= 9.3
- Show tables near a vacuum wraparound order by age
- Based on pg_class
### vacuum_wraparound_table_clean.sql
- Works on PG >= 9.5
- Show VACUUM comands to prevent a vacuum wraparound
- Based on pg_class
### vacuum_wraparound_table_multixact.sql
- Works on PG >= 9.5
- Show tables near a vacuum wraparound due to multixact age
- Base on pg_class
### views.sql
- Show views on currlsent database
- Based on pg_views
### wal.sql
- Works on PG >= 14
- Show current transaction logs (WAL) statistics
- Based on pg_stat_wal
### wal_reciever.sql
- Works on PG >= 9.6
- Show current wal receiver status on a replica
- Based on pg_stat_wal_receiver
