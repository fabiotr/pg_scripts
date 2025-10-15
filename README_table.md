
| Type             | Scope    | Name                                    | Compatibility | Description                       | Reference                 | Comments |
| :---             | :---     | :---                                    | :---:         | :---                              | :---                      | :---     |
| assesment        | cluster  | `archives.sql`                          | PG >= 9.4     | Amount of archives generated | `pg_stat_archiver` | | 
| assesment        | database | `index_big.sql`                         |               | indexes greater than 800KB and greater than 50% of table size | `pg_index` | |
| assesment        | database | `index_functions.sql`                   |               | indexes having expressions on columns | `pg_index` | |
| assesment        | cluster  | `database_size.sql`                     |               | databases on cluster, size and options | `pg_database` | |
| assesment        | database | `index_non_btree.sql`                   |               | indexes non BTREE | `pg_index` and `pg_am` | |
| assesment        | database | `index_non_default_collation.sql`       | PG >= 9.1     | indexes whithout default collation | `pg_index` and `pg_collation` | |
| assesment        | database | `index_partial.sql`                     |               | partial indexes | `pg_index` | |
| assesment        | database | `index_size.sql`                        | PG >= 8.3     | top 20 indexes by size | `pg_class`, `pg_index` | | 
| assesment        | cluster  | `internal.sql`                          |               | some cluster parameters and stats | `current_setting` function | | 
| assesment        | cluster  | `io_cluster.sql`                        | PG >= 16      | I/O stats | `pg_stat_io` | |
| assesment        | database | `materialized_views.sql`                | PG >= 9.3     | materialized views | `pg_class` | |
| assesment        | database | `object_size.sql`                       |               | top 20 objects by size | `pg_class` | | 
| assesment        | cluster  | `pg_config.sql`                         | PG >= 9.6     | compilation parameters | | `pg_config` | |
| assesment        | database | `schemas.sql`                           |               | schemas | `pg_namespaces` | |
| assesment        | database | `tables_changes.sql`                    |               | top 10 tables with more INSERTs, UPDATEs and DELETEs | `pg_stat_user_tables` | |
| assesment        | database | `tables_delete.sql`                     |               | top 10 tables with more DELETEs | `pg_stat_user_tables` | |
| assesment        | database | `tables_fks.sql`                        | PG >= 95      | tables precedence based on FK inheritance | `pg_constraint` | |
| assesment        | database | `tables_foreign.sql`                    | PG >= 9. 1    | Foreign Tables usind FDW | `pg_foreign_table` | | 
| assesment        | cluster  | `shared_buffers_stats.sql`              | PG >= 13      | shared_buffers statistics | `pg_shmen_allocations` | |
| assesment        | cluster  | `slru_stats.sql`                        | PG >= 13      | slru statustics | `pg_stat_slru` | |
| assesment        | database | `tables_insert.sql`                     |               | top 10 tables with more INSERTs | `pg_stat_user_tables` | |
| assesment        | database | `tables_partition.sql`                  | PG >= 12      | partitined objects (tables and indexes) | `pg_class`, `pg_inherits` | |
| assesment        | database | `tables_pk_default_values.sql`          | PG >= 9.0     | Primary Keys (PKs) and it''s default values | `pg_constraint`, `pg_atrribute` | |
| assesment        | database | `tables_rule.sql`                       |               | tables with rules | `pg_rules` | |
| assesment        | database | `tables_size.sql`                       | PG >= 9.5     | top 20 tables by size and it''s free space | `pgstattuple_approx()` function on `pgstattuple` extension | Notice that  pgstatituple_approx(oid) may take a wile to run and overhead your I/O |
| assesment        | database | `tables_uk_default_values.sql`          | PG >= 9.0     | Unique Keys (UKs) and it''s default values | `pg_constraint`, `pg_atrribute` |
| assesment        | database | `tables_unlogged.sql`                   | PG >= 9.3     | unlogged tables | `pg_class` | |
| assesment        | database | `tables_update.sql`                     |               | top 10 tables with more UPDATEs | `pg_stat_user_tables` | |
| assesment        | database | `tablespaces.sql`                       |               | tablespaces | `pg_tablespace`| |
| assesment        | database | `tablespace_objects.sql`                | PG >= 9.4     | number of objects by type for each tablespace | `pg_tablespace` | |
| assesment        | database | `trigger_events.sql`                    | PG >= 9.3     | Event Triggers | `pg_event_trigger` | |
| assesment        | database | `trigger_tables.sql`                    |               | Table Triggers | `pg_trigger`, `pg_proc` | |
| assesment        | database | `views.sql`                             |               | views | `pg_views` | |
| maintenance      | database | `index_dup.sql`                         |               | duplicated indexes that have same columns | `pg_index` |  We recommend check manually other differences before drop any index | |
| maintenance      | database | `index_missing_in_fk.sql`               | PG >= 9.4     | Foreign Keys without an associated index on same columns | `pg_constraint` and `pg_index` | | 
| maintenance      | database | `index_missing_in_fk_create.sql`        | PG >= 9.4     | CREATE INDEX command for every Foreign Keys whithout an associated index on same columns | `pg_constraint` and `pg_index` | |
| maintenance      | database | `index_poor.sql`                        | PG >= 8.4     | indexes with bad performance based on some criterias | `pg_stat_user_indexes` | We advise that this list don''d include other replicas that may use this indexes |
| maintenance      | database | `index_poor_drop.sql`                   |               | DROP INDEX command for every not used index | `pg_stat_user_indexes` | We advise that this list don''d include other replicas that may use this indexes |
| maintenance      | database | `index_stat_btree.sql`                  | PG >= 8.3     | top 20 BTREE indexes that may need a REINDEX (having avg_leaf_density <= 70 OR leaf_fragmentation >= 20) ordered by index size | `pgstatindex(oid)` function on `pgstattuble` extension | Notice that  pgstatindex(oid) may take a wile to run and overhead your I/O |
| maintenance      | database | `index_stat_gin.sql`                    | PG >= 9.3     | statistics about top 20 GIN indexes by size | `pgstginatindex(oid)` function on `pgstattuble` extension | Notice that  pgstatginindex(oid) may take a wile to run and overhead your I/O |
| maintenance      | database | `index_stat_hash.sql`                   | PG >= 10      | statistics about top 20 HASH indexes by size | `pgstathashindex(oid)` function on `pgstattuble` extension | Notice that  pgstathashindex(oid) may take a wile to run and overhead your I/O |
| maintenance      | database | `tables_bloat_approx.sql`               | PG >= 8.3     | top 10 tables with more free space | `pgstattuple_aprrox()` function on `pgstattuple` extension | Notice that pgstattuple_aprrox(oid) may take a wile to run and overhead your I/O |
| maintenance      | database | `tables_index_missing.sql`              | PG >= 8.4     | tables with poor or few indexes and its reasons | `pg_stat_user_tables` | |
| maintenance      | database | `tables_not_used.sql`                   | PG >= 8.3     | Tables with low usage | `pg_stat_user_tables`| |
| maintenance      | database | `tables_not_used_drop.sql`              |               | DROP TABLE commant for tables with low usage | `pg_stat_user_tables` | |
| maintenance      | database | `vacuum_full_or_cluster.sql`            | PG >= 9.5     | VACUUM FULL or CLUSTER commands for tables with more than 20% of free space | `pgstattuple_approx()` function on `pgstattuple` extension | Notice that  pgstattuple_approx(oid) may take a wile to run and overhead your I/O |
| maintenance      | cluster  | `vacuum_wraparound_database.sql`        |               | databases near a vacuum wraparound order by age | `pg_database` | |
| maintenance      | database | `vacuum_wraparound_table.sql`           | PG >= 9.3     | tables near a vacuum wraparound order by age | `pg_class` | |
| maintenance      | database | `vacuum_wraparound_table_clean.sql`     | PG >= 9.5     | VACUUM comands to prevent a vacuum wraparound | `pg_class` | |
| maintenance      | database | `vacuum_wraparound_table_multixact.sql` | PG >= 9.5     | tables near a vacuum wraparound due to multixact age | `pg_class` | |
| migration        | database | `object_privileges_grant.sql`           | PG >= 9.3     | GRANT command for every object privilege | `pg_class`, `pg_roles` | |
| migration        | database | `reindex_on_new_glibc.sql`              | PG >= 9.1     | REINDEX commands to recreate index on varchar and text data types | `pg_collation`, `pg_index` | Use when migrate from a Linux server with GLIBC < 2.28 to a Linux server with GLIBC >= 2.28 |
| migration        | database | `revoke_from_pg_catalog_functions.sql`  | PG >= 9.1 and PG < 12 | REVOKE commands on functions using deprecated data types abstime, reltime and tinterval | `pg_proc` | used to avoid erros when migrating to PG >= 12 | 
| migration        | cluster  | `role_migrate_paas.sql`                 | PG >= 8.4     | Help to migrate roles from a PaaS ou DBaaS (as AWS RDS) where you can't access pg_athid and it's passwords | `pg_roles` | This script is deprecated since PG >= 10, where you can use pg_dumpall --no-role-passwords instead |
| migration        | database | `sequence_setval.sql`                   |               | set sequences values | `pg_class` | Useful when setting a new logical replica |
| migration        | database | `tables_with_oid.sql`                   | PG < 12       | tables with OIDs | `pg_class` | OIDs that become deprecated on PG 12 | 
| object tuning    | database | `autovacuum_analyze.sql`                |               | List ANALYZE and autovacum ANALYZE stats | `pg_stat_user_tables` | | 
| object tuning    | database | `autovacuum_analyze_adjust.sql`         |               | Recomend autovacuum_analyze_scale_factor adjust based on number of rows on table | `pg_stat_user_tables` | | 
| object tuning    | database | `autovacuum_vacuum.sql`                 | PG >= 8.4     | top 20 tables with more percentage of dead rows | `pg_stat_all_tables` | |
| object tuning    | database | `autovacuum_vacuum_+.sql`               | PG >= 9.2     | top 20 tables with more percentage of dead rows with separate values for toast tables | `pg_stat_all_tables`| experimental |
| object tuning    | database | `autovacuum_vacuum_adjust.sql`          | PG >= 8.4     | ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size | Based on `pg_stat_all_tables` |
| object tuning    | database | `autovacuum_vacuum_adjust_+.sql`        | PG >= 8.4     | ALTER TABLE command to adjust autovacuum_vacuum_scale factor based on table size with separate values for toast tables | `pg_stat_all_tables` | experimental |
| object tuning    | database | `fillfactor.sql`                        | PG >= 8.4     | tables having more updates and bad hot update ratio | `pg_stat_user_tables` | |
| object tuning    | database | `functions.sql`                         | PG >= 8.4     | functions consuming more execution time | `pg_stat_user_functions` | |
| object tuning    | database | `object_options.sql`                    |               | objects with options set | `pg_class` | |
| object tuning    | database | `tables_alignment_padding.sql`          | PG >= 94      | Suggested Columns Reorder | | |
| object tuning    | database | `tables_without_index.sql`              |               | tables without any index | `pg_class` | |
| object tuning    | database | `tables_without_pk.sql`                 |               | tables without any Primary Key (PK) | `pg_constraint` | |
| parameter tuning | cluster  | `bgwriter.sql`                          | PG >= 17      | Background Workers stats | `pg_stat_bgwriter` | | 
| parameter tuning | database | `autovacuum_queue.sql`                  |               | next tables where autovacuum will work | `pg_stat_user_tables` |  |
| parameter tuning | cluster  | `checkpoints.sql`                       | PG >= 8.3     | checkpoint stats | `pg_stat_checkpointer` |  |
| parameter tuning | cluster  | `conf_directories.sql`                  | PG >= 8.4     | parameteres about file and directories location | `pg_settings`| |
| parameter tuning | cluster  | `conf_logs.sql`                         |               | parameters about logs configurations and other related | `pg_settings` | |
| parameter tuning | cluster  | `conf_others.sql`                       | PG >= 8.4     | other parameters with non default values | `pg_settings` | | 
| parameter tuning | cluster  | `conf_resource.sql`                     |               | parameters about resource configuration |  `pg_settings` | | 
| parameter tuning | database | `database_stats.sql`                    |               | database stats | `pg_stat_database` | |
| parameter tuning | cluseter | `ls_logs.sql`                           | PG >= 10      | logs size | `pg_ls_logdir()` function | |
| parameter tuning | cluster  | `ls_temp.sql`                           | PG >= 12      | temporary files size | `pg_ls_tempdir()` function | | 
| parameter tuning | cluster  | `ls_wal.sql`                            | PG >= 10      | wal files size | `pg_ls_waldir()` function | |
| parameter tuning | cluster  | `user_options.sql`                      | PG >= 9.0     | roles with parameter options set | `pg_db_role_setting`| |
| parameter tuning | cluster  | `wal.sql`                               | PG >= 14      | transaction logs (WAL) statistics | `pg_stat_wal` | |
| query tuning     | database | `io_index.sql`                          | PG >= 8.4     | I/O stats for indexes | `pg_statio_all_indexes` | |
| query tuning     | database | `io_sequence.sql`                       | PG >= 8.4     | I/O stats for sequences | `pg_statio_all_sequences` | |
| query tuning     | database | `io_table_heap.sql`                     | PG >= 8.4     | I/O stats for heap on tables | `pg_statio_all_tables` | |
| query tuning     | database | `io_table_index.sql`                    | PG >= 9.1     | I/O stats for indexes on tables | `pg_staio_all_tables` | |
| query tuning     | database | `io_table_others.sql`                   | PG >= 9.1     | I/O stats for TOAST and TID on tables | `pg_statio_all_tables` | | 
| query tuning     | database | `statements_calls.sql`                  | PG >= 8.4     | top 10 statements order by calls | `pg_stat_statements` extension | |
| query tuning     | cluster  | `statements_group_database_temp.sql`    | PG >= 9.2     | top 10 statements order by temporary files | `pg_stat_statements` extension | |
| query tuning     | cluster  | `statements_group_database_time.sql`    | PG >= 9.4     | top 10 statements order by execution time | `pg_stat_statements` extension | |
| query tuning     | database | `statements_jit.sql`                    | PG >= 15      | top 10 statements order by jit calls | `pg_stat_statements` extension | |
| query tuning     | database | `statements_local.sql`                  | PG >= 9.2     | top 10 statements order by local memmory used | `pg_stat_statements` extension | |
| query tuning     | database | `statements_plan.sql`                   | PG >= 14      | top 10 statements planing time | `pg_stat_statements` extension | |
| query tuning     | database | `statements_resume.sql`                 | PG >= 14      | top 20 statements order by planing and execution time | `pg_stat_statements` extension | |
| query tuning     | database | `statements_rows.sql`                   | PG >= 8.4     | top 10 statements order by rows | `pg_stat_statements` extension | |
| query tuning     | database | `statements_rows_call.sql`              | PG >= 8.4     | top 10 statements statistics order by rows per call | `pg_stat_statements` extension | |
| query tuning     | database | `statements_shared.sql`                 | PG >= 9.2     | top 10 statements order by shared memmory on disk used | `pg_stat_statements` extension | |
| query tuning     | database | `statements_temp.sql`                   | PG >= 9.2     | top 10 statements order by temporary files | `pg_stat_statements` extension | |
| query tuning     | database | `statements_time.sql`                   | PG >= 8.4     | top 10 statements order by execution time | `pg_stat_statements` extension | |
| query tuning     | database | `statements_top5.sql`                   | PG >= 8.4     | top 5 full query statements order by execution and planing time | `pg_stat_statements` extension | |
| query tuning     | database | `statements_total.sql`                  | PG >= 14      | total statements summary | `pg_stat_statements` extension | |
| query tuning     | database | `statements_wal.sql`                    | PG >= 13      | top 10 statements order by WAL generation | `pg_stat_statements` extension | |
| query tuning     | database | `tables_with_seq_scan.sql`              |               | top 20 tables with more seq scan | `pg_stat_user_tables` | |
| replication      | cluster  | `conf_master.sql`                       | PG >= 8.4     | parameters abous master server replication | `pg_settings` | | 
| replication      | cluster  | `conf_replica.sql`                      | PG >= 8.4     | parameters about slave server replication | `pg_settings` | | 
| replication      | database | `publication_schemas.sql`               | PG >= 15      | publications on schemas | `pg_publication_namespace` | |
| replication      | database | `publication_tables.sql`                | PG >= 12      | publications on tables | `pg_publication_tables` | | 
| replication      | database | `publications.sql`                      | PG >= 10      | publications | `pg_publication` | |
| replication      | cluster  | `replication_origin.sql`                | PG >= 9.5     | replication origins created and associated status if exists | `pg_replication_origin`, `pg_replication_origin_status` | 
| replication      | cluster  | `replication_slots.sql`                 | PG >= 9.5     | replication slots | `pg_replication_slots` | |
| replication      | cluster  | `replication_stats.sql`                 | PG >= 9.5     | replication stats on master | `pg_stat_replication` | |
| replication      | database | `subscription_rel_stats.sql`            | PG >= 10      | tables logical replication stats from subscription | `pg_subscripton_rel` | |
| replication      | database | `subscription_stats.sql`                | PG >= 10      | logical replication stats from subscriptions | `pg_stat_subscription`, `pg_stat_subscription_stats` | |
| replication      | cluster  | `wal_reciever.sql`                      | PG >= 9.6     | wal receiver status on a replica | `pg_stat_wal_receiver` | |
| security         | cluster  | `backup.sql`                            | PG >= 9.1     | Look for a `.backup` file with physical backup summary at pg_wal or pg_xlog | `pg_pg_read_file()` and `pg_ls_dir` functions | | 
| security         | cluster  | `conf_recovery.sql`                     | PG >= 8.4     | parameters about backup recovery | Based on `pg_settings` | |
| security         | cluster  | `connections_gss.sql`                   | PG >= 12      | total connections stats runing now using GSS |   `pg_stat_gssapi` | |
| security         | cluster  | `connections_runing_ssl.sql`            | PG >= 9.5     | total connections stats running now using SSL | `pg_stat_ssl` | |
| security         | database | `object_privileges_list.sql`            |               | privileges on objects | `pg_class`, `pg_roles` | |
| security         | cluster  | `pg_hba.sql`                            | PG >= 10      | pg_hba.conf non commented lines and erros | `pg_hba_file_rules` | list rules even if they are not active yet after any change on pg_hba.conf file | 
| security         | cluster  | `security_labes.sql`                    | PG >= 9.1     | security labels on SE Linux Security Policies | `pg_seclabels` | |
| security         | database | `security_policies.sql`                 | PG >= 9.5     | policies for Row Level Security | `pg_policies` | |
| security         | database | `user_default_privileges.sql`           | PG >= 9.0     | Default privileges | `pg_default_acl` | |
| security         | database | `user_granted_parameters.sql`           | PG >= 15      | privileges on parameters | `pg_parameter_acl` | |
| security         | cluster  | `user_granted_roles.sql`                |               | granted roles to other roles | `pg_auth_members` | |
| security         | database | `user_owners_x_connections.sql`         |               | current number of connections and objets owned by each role | `pg_stat_activity`, `pg_class` | |
| security         | cluster  | `user_priv.sql`                         |               | roles with hight privileges options like superusers | `pg_roles` | |
| troubleshooting  | cluster  | `connections_runing.sql`                |               | active connections stats runing now | Based on `pg_stat_activity` | |
| troubleshooting  | cluster  | `connections_runing_detais.sql`         |               | active detailed connections stats runing now | `pg_stat_activity` | |
| troubleshooting  | cluster  | `connections_tot.sql`                   | PG >= 9.2     | total active connections stats running now | `pg_stat_activity` | |
| troubleshooting  | cluster  | `database_standby_conflicts.sql`        | PG >= 9.1     | queries canceled on standby due to conflicts with master | `pg_database_conflicts` | |
| troubleshooting  | database | `index_check_btree_integrity.sql`       | PG >= 10      | check integrity on every BTREE index | | `bt_index_check(oid)` function on `amcheck` extension | | 
| troubleshooting  | database | `index_check_gin_integrity.sql`         | PG >= 18      | check integrity on every GIN index | `bt_index_check(oid)` function on `amcheck` extension | |
| troubleshooting  | database | `index_invalid.sql`                     |               | indexes marked as invalid | `pg_index` | |
| troubleshooting  | cluster  | `locks.sql`                             | PG >= 8.3     | Locks | `pg_locks`, `pg_stat_activity` | | 
| troubleshooting  | cluster  | `pgbouncer_fdw.sql`                     |               | Script to create viws to pgbouncer virtual database SHOW commands | `dblink` extension | | 
| troubleshooting  | cluster  | `prepared_transactions.sql`             |               | current prepared transactions | `pg_prepared_xacts` | | 
| troubleshooting  | cluster  | `progress_analyze.sql`                  | PG >= 13      | status about ANLYZE commands running | `pg_stat_progress_analyze` | |
| troubleshooting  | cluster  | `progress_basebackup.sql`               | PG >= 13      | status about pg_basebackup running | `pg_stat_progress_basebackup` | |
| troubleshooting  | cluster  | `progress_cluster.sql`                  | PG >= 12      | status about CLUSTER commands running | `pg_stat_progress_cluster` | |
| troubleshooting  | cluster  | `progress_copy.sql`                     | PG >= 14      | status about COPY commands running | `pg_stat_progress_copy` | |
| troubleshooting  | cluster  | `progress_index.sql`                    | PG >= 12      | status about CREATE INDEX commands running | `pg_stat_progress_create_index` | |
| troubleshooting  | cluster  | `progress_vacuum.sql`                   | PG >= 9.6     | status about VACUUM commands running | `pg_stat_progress_vacuum` | |

