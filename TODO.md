
- Better semantics for bgwriter.sql, checkpoint.sql and io_cluster.sql
- ~~Create new statements to all cluster, grouping databases and users, by plan time, shared buffers and WAL~~ (see `statements_cluster_total_by_database.sql` and `statements_cluster_total_by_user.sql`)
- ~~Create scripts for Foreign Server, user mappings (using pg_user_mappings)~~ (see `foreign_servers.sql`)
- ~~Create an autovacuum script based on new PG 18 columns in pg_stat_user_tables to see how long autovacuum is taking in each table.~~ (see `autovacuum_vacuum_duration.sql` and `autovacuum_analyze_duration.sql`)
- ~~Create a new connections_running script to show memory and WAL use for each user session based on new PG 18 function pg_stat_get_backend_io() and pg_stat_get_backend_wal()~~ (see `connections_io.sql`)
- ~~Update tables_partition.sql using pg_partitioned_table~~
- ~~Update replication_slots script using pg_stat_replication_slots (added on PG 14)~~
