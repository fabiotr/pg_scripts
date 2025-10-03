# DBA PostgreSQL SQL scripts
## Scripts tested from PostgreSQL 8.2 to PostgreSQL 18

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
- Works on PG >= 9.2
- Look for a .backup file with physical backup summary at pg_wal or pg_xlog
- Based on pg_pg_read_file and pg_ls_dir  
### bgwriter.sql
- Works on PG >= 17
- Show Background Workers stats
- Based on pg_stat_bgwriter
### checkpoints.sql
- Show checkpoint stats
- Based on pg_stat_checkpointer
### conf_directories.sql
- Show parameteres about file and directories location
- Based on pg_settings
### conf_logs.sql
- Show parameters about logs configurations and other that could be collected
- Based on pg_settings
### conf_master.sql
- Show parameters abous master server replication
- Based on pg_settings
### conf_others.sql
- Show other parameters with non default values
- Based on pg_settings
### conf_recovery.sql
- Show parameters about backup recovery
- Based on pg_settings
### conf_replica.sql
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
- Works on PG >= 8.3
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
- Show Foreign Keys on current database that don't have an associated index on same columns
- Based on pg_constraint and pg_index 
### index_missing_in_fk_create.sql
- Show a CREATE INDEX command for every Foreign Keys on current database that don't have an associated index on same columns
- Based on pg_constraint and pg_index 
### index_non_btree.sql
- Show indexes non BTREE used on current database
- Based on pg_index and pg_am
### index_non_default_collation.sql
- Show indexes on current database that don't use default collation
- Based on pg_index and pg_collation
### index_partial.sql
- Show partial indexes on current database
- Based on pg_index
### index_poor_drop.sql
- Show a DROP INDEX command for every index on current database with bad performance based on some criterias. We advise that this list don'd include other replicas that may use this indexes
- Based on pg_stat_user_indexes
### index_poor.sql
- Show indexes on current database with bad performance based on some criterias. We advise that this list don'd include other replicas that may use this indexes
- Based on pg_stat_user_indexes
### index_size.sql
- Show indexes size on current database
- Based on pg_class
### internal.sql
- Show some cluster parameters
### io_cluster.sql
- Works on PG >= 16
- Show I/O stats
- Based on pg_stat_io
### io_index.sql

### io_sequence.sql
### io_table_heap.sql
### io_table_index.sql
### io_table_others.sql
### locks.sql
### log_size.sql (PG >= 10)
### ls_logs.sql (PG >= 10)
### ls_temp.sql (PG >= 12)
### ls_wal.sql (PG >= 10)
### materialized_views.sql
### object_privileges_grant.sql
### object_privileges_list.sql
### object_size.sql
### pg_config.sql (PG >= 9.6)
### pg_hba.sql (PG >= 10)
### pgbouncer_fdw.sql
### prepared_transactions.sql
### progress_analyze.sql (PG >= 13)
### progress_basebackup.sql (PG >= 13)
### progress_cluster.sql (PG >= 12)
### progress_copy.sql (PG >= 14)
### progress_index.sql (PG >= 12)
### progress_vacuum.sql (PG >= 9.6)
### publication_schemas.sql (PG >= 15)
### publication_tables.sql (PG >= 12)
### publications.sql (PG >= 10)
### reindex_on_new_glibc.sql
### reloptions.sql
### relsize.sql
### replication_origin.sql (PG >= 9.5)
### replication_slots.sql (PG >= 9.5)
### replication_stats.sql (PG >= 9.5)
### revoke_from_pg_catalog_functions.sql (PG < 12)
### role_migrate_paas.sql
### schemas.sql
### security_labes.sql (PG >= 9.1)
### security_policies.sql (PG >= 9.5)
### sequence_setval.sql
### shared_buffers_stats.sql (PG >= 13)
### slru_stats.sql (PG >= 13)
### stat_functions.sql
### statements.sql
### statements_call.sql (PG >= 8.4)
### statements_group_database_temp.sql (PG >= 9.2)
### statements_group_database_time.sql (PG >= 9.4)
### statements_jit.sql (PG >= 15)
### statements_local.sql (PG >= 9.2)
### statements_plan.sql (PG >= 14)
### statements_resume.sql (PG >= 14)
### statements_rows.sql (PG >= 8.4)
### statements_rows_call.sql (PG >= 8.4)
### statements_shared.sql (PG >= 9.2)
### statements_temp.sql (PG >= 9.2)
### statements_time.sql (PG >= 8.4)
### statements_top5.sql ((PG >= 8.4)
### statements_total.sql (PG >= 14)
### statements_wal.sql (PG >= 13)
### subscription_rel_stats.sql
### subscription_stats.sql
### tables_alignment_padding.sql
### tables_bloat_approx.sql
### tables_changes.sql
### tables_delete.sql
### tables_fks.sql
### tables_foreign.sql (PG >= 9.2)
### tables_index_missing.sql
-
### tables_insert.sql
### tables_not_used.sql
### tables_not_used_drop.sql
### tables_partition.sql (PG >= 12)
### tables_pk_default_values.sql
### tables_rule.sql
### tables_size.sql
### tables_uk_default_values.sql
### tables_unlogged.sql
### tables_update.sql
### tables_with_oid.sql (PG < 12)
### tables_with_seq_scan.sql
### tables_without_index.sql
### tables_without_pk.sql
### tablespace_objects.sql (PG >= 9.4)
### tablespaces.sql
### trigger_events.sql (PG >= 9.3)
### trigger_tables.sql
### user_default_privileges.sql (PG >= 9.0)
### user_granted_parameters.sql (PG >= 15)
### user_granted_roles.sql
### user_options.sql (PG >= 9.0)
### user_owners_x_connections.sql
### user_priv.sql
### vacuum.sql
### vacuum_+.sql
### vacuum_adjust.sql
### vacuum_adjust_+.sql
### vacuum_full_or_cluster.sql
### vacuum_wraparound.sql
### vacuum_wraparound_database.sql
### vacuum_wraparound_table.sql
### vacuum_wraparound_table_clean.sql
### vacuum_wraparound_table_multixact.sql
### views.sql
- wal.sql (PG >= 14)
- wal_reciever.sql (PG >= 9.6)
