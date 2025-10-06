# DBA PostgreSQL SQL scripts
- Scripts tested from PostgreSQL 8.2 to PostgreSQL 18
- The scripts detects your current PostgreSQL version and call the correct script automatically 

### analyze.sql
- List ANALYZE and autovacum ANALYZE stats
- Based on pg_stat_user_tables
### analyze_adjust.sql
- Recomend autovacuum_analyze_scale_factor adjust based on number of rows on table
- Based on pg_stat_user_tables
### archives.sql
- Works on PG >= 9.4 
- Show amount of archives generated
- Based on pg_stat_archiver
### autovacuum_queue.sql
- Shows next tables where autovacuum will work
- Based on pg_stat_user_tables
### backup.sql
- Works on PG >= 9.1
- Look for a .backup file with physical backup summary at pg_wal or pg_xlog
- Based on pg_pg_read_file and pg_ls_dir  
### bgwriter.sql
- Works on PG >= 17
- Show Background Workers stats
- Based on pg_stat_bgwriter
### checkpoints.sql
- Works on PG >= 8.3
- Show checkpoint stats
- Based on pg_stat_checkpointer
### conf_directories.sql
- Works on PG >= 8.4
- Show parameteres about file and directories location
- Based on pg_settings
### conf_logs.sql
- Show parameters about logs configurations and other that could be collected
- Based on pg_settings
### conf_master.sql
- Works on PG >= 8.4
- Show parameters abous master server replication
- Based on pg_settings
### conf_others.sql
- Works on PG >= 8.4
- Show other parameters with non default values
- Based on pg_settings
### conf_recovery.sql
- Works on PG >= 8.4
- Show parameters about backup recovery
- Based on pg_settings
### conf_replica.sql
- Works on PG >= 8.4
- Show parameters about slave server replication
- Based on pg_settings
### conf_resource.sql
- Show parameters about resource configuration
- Based on pg_settings
### connections_gss.sql
- Works on PG >= 12
- Show total connections stats runing now using GSS
- Based on pg_stat_gssapi
### connections_runing.sql
- Show active connections stats runing now
- Based on pg_stat_activity
### connections_runing_detais.sql
- Show active detailed connections stats runing now
- Based on pg_stat_activity
### connections_runing_ssl.sql
- Works on PG >= 9.5
- Show total connections stats running now using SSL
- Based on pg_stat_ssl
### connections_tot.sql
- Works on PG >= 9.2
- Show total active connections stats running now
- Based on pg_stat_activity
### database_size.sql
- Show all databases on cluster, size and options
- Based on pg_database
### database_standby_conflicts.sql
- Works on PG >= 9.1
- Show database queries canceled on standby due to conflicts with master
- Based on pg_database_conflicts
### database_stats.sql
- Show current database stats
- Based on pg_stat_database
### fillfactor.sql 
- Works on PG >= 8.4
- Show tables on current database that have more updates and bad hot update percent
- Based on pg_stat_user_tables
### functions.sql 
- Works on PG >= 8.4
- Show functions on current database that consume more execution time
- Based on pg_stat_user_functions
### index_big.sql
- Show indexes on current database greater than 800KB and greater than 50% of table size
- Based on pg_index
### index_check_btree_integrity.sql
- Works on PG >= 10
- Run bt_index_check(oid) function on every BTREE index on current database
- Based on amcheck extension
### index_check_gin_integrity.sql
- Works on PG >= 18
- Run bt_index_check(oid) function on every GIN index on current database
- Based on amcheck extension
### index_dup.sql
- Show duplicated indexes on current database that have same columns. We recommend check manually other differences before drop any index.
- Based on pg_index
### index_functions.sql
- Show indexes on current database that have expressions on columns
- Based on pg_index
### index_invalid.sql
- Show indexes on current database that are marked as invalid
- Based on pg_index
### index_missing_in_fk.sql
- Works on PG >= 9.4
- Show Foreign Keys on current database that don't have an associated index on same columns
- Based on pg_constraint and pg_index 
### index_missing_in_fk_create.sql
- Works on PG >= 9.4
- Show a CREATE INDEX command for every Foreign Keys on current database that don't have an associated index on same columns
- Based on pg_constraint and pg_index 
### index_non_btree.sql
- Show indexes non BTREE used on current database
- Based on pg_index and pg_am
### index_non_default_collation.sql
- Works on PG >= 9.1
- Show indexes on current database that don't use default collation
- Based on pg_index and pg_collation
### index_partial.sql
- Show partial indexes on current database
- Based on pg_index
### index_poor.sql
- Works on PG >= 8.4
- Show indexes on current database with bad performance based on some criterias. We advise that this list don'd include other replicas that may use this indexes
- Based on pg_stat_user_indexes
### index_poor_drop.sql
- Show a DROP INDEX command for every index on current database with bad performance based on some criterias. We advise that this list don'd include other replicas that may use this indexes
- Based on pg_stat_user_indexes
### index_size.sql
- Works on PG >= 8.3
- Show top 20 indexes size on current database
- Based on pg_class and pg_index
### index_stat_btree.sql
- Works on PG >= 8.3
- Show top 20 BTREE indexes that may need a REINDEX (having avg_leaf_density <= 70 OR leaf_fragmentation >= 20) ordered by index size
- Based on pg_class and pgstatindex(oid) function on pgstattuble extension
- Notice that  pgstatindex(oid) may take a wile to run and overhead your I/O
### index_stat_gin.sql
- Works on PG >= 9.3
- Show statistics about top 20 GIN indexes size on current database
- Based on pg_class and pgstginatindex(oid) function on pgstattuble extension
- - Notice that  pgstatginindex(oid) may take a wile to run and overhead your I/O
### index_stat_hash.sql
- Works on PG >= 10
- Show statistics about top 20 HASH indexes size on current database
- Based on pg_class and pgstathashindex(oid) function on pgstattuble extension
- - Notice that  pgstathashindex(oid) may take a wile to run and overhead your I/O
### internal.sql
- Show some cluster parameters
### io_cluster.sql
- Works on PG >= 16
- Show I/O stats
- Based on pg_stat_io
### io_index.sql
- Works on PG >= 8.4
- Show I/O stats for indexes on current database
- Based on pg_statio_all_indexes
### io_sequence.sql
- Works on PG >= 8.4
- Show I/O stats for sequences on current database
- Based on pg_statio_all_sequences
### io_table_heap.sql
- Works on PG >= 8.4
- Show I/O stats for heap tables on current database
- Based on pg_statio_all_tables
### io_table_index.sql
- Works on PG >= 9.1
- Show I/O stats for index tables on current database
- Based on pg_staio_all_tables
### io_table_others.sql
- Works on PG >= 9.1
- Show I/O stats for TOAST, and TID tables on current database
- Based on pg_statio_all_tables
### locks.sql
- Works on PG >= 8.3
- Show current Locks
- Based on pg_locks and pg_stat_activity
### ls_logs.sql 
- Works on PG >= 10
- Show current logs size
- Based on pg_ls_logdir() function
### ls_temp.sql 
- Works on PG >= 12
- Show current temporary files size
- Based on pg_ls_tempdir() function
### ls_wal.sql 
- Works on PG >= 10
- Show current wal files size
- Based on pg_ls_waldir() function
### materialized_views.sql
- Works on PG >= 9.3
- Show materialized views on current database
- Based on pg_class
### object_options.sql
- List objects with options set
- Based on pg_class
### object_privileges_list.sql
- Show privileges on objects on current database
- Based on pg_class and pg_roles
### object_privileges_grant.sql
- Works on PG >= 9.3
- Show GRANT command for every privilege on objects on current database
- Based on pg_class and pg_roles
### object_size.sql
- Show top 20 objects size on current database
- Based on pg_class
### pg_config.sql 
- Works on PG >= 9.6
- Show compilation parameters
- Based on pg_config
### pg_hba.sql 
- Works on PG >= 10
- Show pg_hba.conf non commented lines and erros
- Based on pg_hba_file_rules
### pgbouncer_fdw.sql
- Script to create viws to pgbouncer virtual database SHOW commands
- Based on dblink extension
### prepared_transactions.sql
- Show current prepared transactions
- Based on pg_prepared_xacts
### progress_analyze.sql 
- Works on PG >= 13
- Show status about ANLYZE commands running now
- Based on pg_stat_progress_analyze
### progress_basebackup.sql
- Works on PG >= 13
- Show status about pg_basebackup running now
- Based on pg_stat_progress_basebackup
### progress_cluster.sql 
- Works on PG >= 12
- Show status about CLUSTER commands running now
- Based on pg_stat_progress_cluster
### progress_copy.sql 
- Works on PG >= 14
- Show status about COPY commands running now
- Based on pg_stat_progress_copy
### progress_index.sql 
- Works on PG >= 12
- Show status about CREATE INDEX commands running now
- Based on pg_stat_progress_create_index
### progress_vacuum.sql 
- Works on PG >= 9.6
- Show status about VACUUM commands running now
- Based on pg_stat_progress_vacuum
### publication_schemas.sql
  - Works on PG >= 15
  - Show all publications on schemas on current database
  - Based on pg_publication_namespace
### publication_tables.sql
- Works on PG >= 12
- Show all publications on tables on current database
- Based on pg_publication_tables
### publications.sql 
- Works on PG >= 10
- Show all publications
### reindex_on_new_glibc.sql
- Works on PG >= 9.1
- Create REINDEX commands to recreate index when make a migration from a Linux server with GLIBC < 2.28 to a Linux server with GLIBC >= 2.28
- Based on pg_index and pg_collation
### replication_origin.sql 
- Works on PG >= 9.5
- Show replication origins created and associated status if exists
- Based on pg_replication_origin an pg_replication_origin_status
### replication_slots.sql 
- Works on PG >= 9.5
- Show current replication slots
- Based on pg_replication_slots
### replication_stats.sql 
- Works on PG >= 9.5
- Shows current replication stats on master
- Based on pg_stat_replication
### revoke_from_pg_catalog_functions.sql 
- Works on PG >= 9.1 AND PG < 12
- Shows REVOKE commands to avoid erros when migrating to PG >= 12 on functions using deprecated data types abstime, reltime and tinterval
- Based on pg_proc 
### role_migrate_paas.sql
- Works on PG >= 8.4
- Help to migrate roles from a PaaS ou DBaaS (as AWS RDS) where you can't access pg_athid and it's passwords
- This script is deprecated since PG >= 10, where you can use pg_dumpall --no-role-passwords instead
- Based on pg_roles
### schemas.sql
- Show all schemas
- Based on pg_namespaces and pg_class
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
### vacuum.sql
- Works on PG >= 8.4
- Show current top 20 tables with more percentage of dead rows
- Based on pg_stat_all_tables
### vacuum_+.sql
- Works on  PG >= 9.2
- Show current top 20 tables with more percentage of dead rows with separate values for toast tables (experimental)
- Based on pg_stat_all_tables
### vacuum_adjust.sql
- Works on PG >= 8.4
- Show ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size
- Based on pg_stat_all_tables
### vacuum_adjust_+.sql
- Works on PG >= 8.4
- Show ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size with separate values for toast tables (experimental)
- Based on pg_stat_all_tables
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
