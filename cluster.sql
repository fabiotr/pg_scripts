psql -v "cliente=storyblok" -h sbmainprod6.cb1a3ra0uyyf.eu-central-1.rds.amazonaws.com  -p 5432 -U fabio.telles@storyblok.com  -d ebdb  -f report_cluster_markdown_output.sql 
# Relatório de informações sobre o Cluster

Índice

[[_TOC_]]

## Informações sobre o serviço

- **Host**: *
- **Porta**: 5432
- **Versão**: [13.4](https://www.postgresql.org/docs/13/release.html)

## postgresql.conf

### Diretorios

          conf           |               value               
-------------------------|-----------------------------------
 unix_socket_directories | /tmp
 config_file             | /rdsdbdata/config/postgresql.conf
 data_directory          | /rdsdbdata/db
 external_pid_file       | 
 hba_file                | /rdsdbdata/config/pg_hba.conf
 ident_file              | /rdsdbdata/config/pg_ident.conf
 log_directory           | /rdsdbdata/log/error
 archive_command         | (disabled)


### Recursos

         conf         | current_setting 
----------------------|-----------------
 effective_cache_size | 355496200kB
 autovacuum_work_mem  | 16343226kB
 maintenance_work_mem | 8372MB
 shared_buffers       | 355496200kB
 temp_buffers         | 8MB
 work_mem             | 32MB
 max_wal_size         | 1GB
 min_wal_size         | 512MB
 wal_buffers          | 16MB


### Logs

  OK  |            conf             |            value             |       source       
------|-----------------------------|------------------------------|--------------------
**!!**| lc_messages                 |                              | default
 --   | TimeZone                    | UTC                          | configuration file
 OK   | shared_preload_libraries    | rdsutils,pg_stat_statements  | configuration file
 OK   | log_autovacuum_min_duration | 0                            | configuration file
**!!**| log_checkpoints             | off                          | default
 OK   | log_connections             | on                           | configuration file
 OK   | log_disconnections          | on                           | configuration file
 OK   | log_duration                | off                          | default
 OK   | log_hostname                | off                          | configuration file
 --   | log_line_prefix             | %t:%r:%u@%d:[%p]:            | configuration file
 OK   | log_lock_waits              | on                           | configuration file
**!!**| log_statement               | none                         | default
 OK   | log_temp_files              | 0                            | configuration file
 OK   | log_timezone                | UTC                          | configuration file
 OK   | log_min_duration_statement  | 1000                         | configuration file
 OK   | log_min_messages            | warning                      | default
 OK   | log_destination             | stderr                       | configuration file
 --   | log_directory               | /rdsdbdata/log/error         | configuration file
 --   | log_filename                | postgresql.log.%Y-%m-%d-%H%M | configuration file
 OK   | logging_collector           | on                           | configuration file
**!!**| log_rotation_age            | 60                           | configuration file
 OK   | log_rotation_size           | 100000                       | configuration file
 OK   | track_activity_query_size   | 4096                         | configuration file
 OK   | track_activities            | on                           | default
 OK   | track_counts                | on                           | default
 OK   | track_functions             | all                          | configuration file
 OK   | track_io_timing             | on                           | configuration file


### Outros
                conf                 |                  value                  |      default       |   unit   
-------------------------------------|-----------------------------------------|--------------------|----------
 autovacuum_analyze_scale_factor     | 0.05                                    | 0.1                | SEM INFO
 autovacuum_max_workers              | 8                                       | 3                  | SEM INFO
 autovacuum_naptime                  | 5                                       | 60                 | s
 autovacuum_vacuum_cost_delay        | 5                                       | 2                  | ms
 autovacuum_vacuum_cost_limit        | 3000                                    | -1                 | SEM INFO
 autovacuum_vacuum_scale_factor      | 0.1                                     | 0.2                | SEM INFO
 TimeZone                            | UTC                                     | GMT                | SEM INFO
 idle_in_transaction_session_timeout | 86400000                                | 0                  | ms
 max_connections                     | 5000                                    | 100                | SEM INFO
 unix_socket_group                   | rdsdb                                   |                    | SEM INFO
 ssl                                 | on                                      | off                | SEM INFO
 ssl_ca_file                         | /rdsdbdata/rds-metadata/ca-cert.pem     |                    | SEM INFO
 ssl_cert_file                       | /rdsdbdata/rds-metadata/server-cert.pem | server.crt         | SEM INFO
 ssl_key_file                        | /rdsdbdata/rds-metadata/server-key.pem  | server.key         | SEM INFO
 ssl_max_protocol_version            | TLSv1.2                                 |                    | SEM INFO
 pg_stat_statements.track            | all                                     | top                | SEM INFO
 rds.force_autovacuum_logging_level  | warning                                 | disabled           | SEM INFO
 rds.internal_databases              | rdsadmin                                | rdsadmin,template0 | SEM INFO
 max_replication_slots               | 20                                      | 10                 | SEM INFO
 max_wal_senders                     | 20                                      | 10                 | SEM INFO
 hot_standby                         | off                                     | on                 | SEM INFO
 hot_standby_feedback                | on                                      | off                | SEM INFO
 max_standby_streaming_delay         | 14000                                   | 30000              | ms
 wal_receiver_timeout                | 30000                                   | 60000              | ms
 maintenance_io_concurrency          | 1                                       | 10                 | SEM INFO
 max_parallel_workers                | 32                                      | 8                  | SEM INFO
 max_worker_processes                | 128                                     | 8                  | SEM INFO
 vacuum_cost_page_miss               | 0                                       | 10                 | SEM INFO
 huge_pages                          | on                                      | off                | SEM INFO
 max_stack_depth                     | 6144                                    | 100                | kB
 stats_temp_directory                | /rdsdbdata/db/pg_stat_tmp               | pg_stat_tmp        | SEM INFO
 archive_command                     | (disabled)                              |                    | SEM INFO
 archive_timeout                     | 300                                     | 0                  | s
 checkpoint_timeout                  | 60                                      | 300                | s


## pg_hba.conf

 l  | type  |   database    | user_name  | address  | netmask  | auth_method 
----|-------|---------------|------------|----------|----------|-------------
  2 | local | {all}         | {rdsadmin} | SEM INFO | SEM INFO | peer
  6 | local | {all}         | {all}      | SEM INFO | SEM INFO | md5
 12 | host  | {all}         | {rdsadmin} | all      | SEM INFO | reject
 13 | host  | {rdsadmin}    | {all}      | all      | SEM INFO | reject
 14 | host  | {all}         | {all}      | all      | SEM INFO | md5
 15 | host  | {replication} | {all}      | samehost | SEM INFO | md5


## Connections
 state  | count |    avg_query    |    max_query    |    avg_xact     |    max_xact     
--------|-------|-----------------|-----------------|-----------------|-----------------
 active |     3 | 00:00:00.006937 | 00:00:00.0174   | 00:00:00.007214 | 00:00:00.017676
 idle   |   983 | 00:00:35.273046 | 00:06:01.446081 | SEM INFO        | SEM INFO


## Users with high privileges

   role   | login |  super   | c_db | c_role |   rep    |   member_of   
----------|-------|----------|------|--------|----------|---------------
 ebroot   | X     | SEM INFO | X    | X      | SEM INFO | rds_superuser
 rdsadmin | X     | X        | X    | X      | X        | SEM INFO


| Info | Valor 
|---|---|
Checkpoints timed  |  100.0 %
Checkpoints req    |    0.0 %
------------------ | -------
Written checkpoint | SEM INFO
Written backend    | SEM INFO
Written clean      | SEM INFO
------------------ | -------
Size               | 0 bytes / s


## Databases size

 Database  |   Size   | Connections 
-----------|----------|-------------
 SEM INFO  | SEM INFO |           0
 ebdb      | 1907 GB  |         984
 rdsadmin  | 8839 kB  |           4
 postgres  | 8239 kB  |           0
 template0 | 8089 kB  |           0
 template1 | 8065 kB  |           0


FIM

