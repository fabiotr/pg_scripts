\set QUIET on
\timing off
-- WARNING
-- psql must be >= pg10 to run this script

--Setup
SET client_encoding TO 'UTF8';
SET client_min_messages TO WARNING;
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
RESET client_min_messages;
\r
--Vars
SELECT
     current_date                                          AS date    
    ,current_setting('server_version_num')::int >=  90000  AS pg_90
    ,current_setting('server_version_num')::int >=  90100  AS pg_91
    ,current_setting('server_version_num')::int >=  90500  AS pg_95
    ,current_setting('server_version_num')::int >= 100000  AS pg_10
    ,current_setting('server_version_num')::int >= 120000  AS pg_12
    ,current_setting('server_version_num')::int <  120000  AS under_pg_12
    ,NOT pg_is_in_recovery()                               AS not_standby
    ,(SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_publication) AS publication
    ,(SELECT CASE WHEN count(1) = 0 THEN FALSE ELSE TRUE END FROM pg_subscription) AS subscription
\gset svp_

\pset footer off
\pset null ' - '
\pset border 1
\pset pager off
-- Markdown format
\o | sed 's/+--/\|--/g' | sed 's/--+/--\|/g' | sed 's/^\s\(\s\+\)/\|\1/' | sed 's/-\[ RECORD .*/\| Info \| Valor \n\|---\|---\|/'

--Report
\qecho # Report for database :DBNAME
\qecho - Date:     :svp_date
\qecho - Host:     :HOST
\qecho - Port:     :PORT
\qecho - Version:  :SERVER_VERSION_NAME
\qecho

\qecho '# Index'
\qecho
\qecho [[_TOC_]]
\qecho


\qecho '## Database stats'
\qecho
\i database_stats.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby
    \qecho '## Extensions'
    \qecho
    \i extensions.sql
    \qecho

    \qecho '## Roles'
    \qecho

    \qecho '### Default privileges'
    \qecho
    \i user_default_privileges.sql
    \qecho
  \endif
\endif

\qecho '### Owner X Conections'
\qecho
\i user_owners_x_connections.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby
    \qecho '### Row level security'
    \qecho
    \i security_policies.sql
    \qecho

    \qecho '### Security Label'
    \qecho
    \i security_labes.sql
    \qecho
 
  \endif
\endif


\if :svp_pg_10
  \if :svp_publication

    \qecho '## Logical Replication publications'
    \qecho

    \qecho '### Publications'
    \qecho
    \i publications.sql
    \qecho

    \qecho '### Schemas in publications'
    \qecho
    \i publication_schemas.sql
    \qecho

    \qecho '### Tables in publications'
    \qecho
    \i publication_tables.sql
    \qecho
  \endif

  \if :svp_subscription

    \qecho '## Logical Replication subscriptions'
    \qecho

    \qecho '### Subscriptions'
    \qecho
    \i subscription_stats.sql
    \qecho

    \qecho '### Tables in subscriptions'
    \qecho
    \i subscription_rel_stats.sql
    \qecho
  \endif
\endif


\qecho '## I/O'
\qecho

\qecho '### I/O on tables (heap)'
\qecho
\i io_table_heap.sql
\qecho

\qecho '### I/O on tables (others)'
\qecho
\i io_table_others.sql
\qecho

\qecho '### I/O on tables (indexes)'
\qecho
\i io_table_index.sql
\qecho


\qecho '### I/O on indexes'
\qecho
\i io_index.sql
\qecho

\qecho '### I/O on sequences'
\qecho
\i io_sequence.sql
\qecho


\if :svp_pg_90
  \if :svp_not_standby
    \qecho '## Database DML'
    \qecho

    \qecho '#### INSERT + UPDATE + DELETE stats'
    \qecho
    \i tables_changes.sql
    \qecho

    \qecho '### INSERT stats'
    \qecho
    \i tables_insert.sql
    \qecho

    \qecho '### UPDATE stats'
    \qecho
    \i tables_update.sql
    \qecho

    \qecho '### DELETE stats'
    \qecho
    \i tables_delete.sql
    \qecho


    \qecho '## Tablespaces objects'
    \qecho 
    \i tablespace_objects.sql
    \qecho


    \qecho '## Schemas'
    \qecho
    \i schemas.sql
    \qecho

    \qecho '## Views'
    \qecho
    \i views.sql
    \qecho

    \qecho '## Top objects'
    \qecho
    \i object_size.sql
    \qecho

    \qecho '## Triggers'
    \qecho

    \qecho '### Event Triggers'
    \qecho
    \i trigger_events.sql
    \qecho


    \qecho '## Tables'
    \qecho

    \qecho '### Tables size'
    \qecho
    \i tables_size.sql
    \qecho

    \qecho '### Tables unlogged'
    \qecho
    \i tables_unlogged.sql
    \qecho
	
	
    \qecho '### Table Triggers'
    \qecho
    \i trigger_tables.sql
    \qecho
	
    \qecho '### Tables with unused space'
    \qecho
    \i tables_bloat_approx.sql
    \qecho

    \qecho '### Tables with unused space cleanup'
    \qecho
    \i vacuum_full_or_cluster.sql
    \qecho
	
    \qecho '### Tables without PK'
    \qecho
    \i tables_without_pk.sql
    \qecho

    \qecho '### Tables without any Index'
    \qecho
    \i tables_without_index.sql
    \qecho

    \if :svp_under_pg_12
      \qecho '### Tables with OID'
      \qecho
      \i tables_with_oid.sql
      \qecho
    \endif
	
  \endif
\endif

\qecho '### Tables with seq scan'
\qecho
\i tables_with_seq_scan.sql
\qecho

\qecho '### Not used tables'
\qecho
\i tables_not_used.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby

    \qecho '### Partition tables'
    \qecho
    \i tables_partition.sql
    \qecho

    \qecho '### Materialized Views'
    \qecho
    \i materialized_views.sql
    \qecho

    \qecho '### Foreign Tables'
    \qecho
    \i tables_foreign.sql
    \qecho
  \endif
\endif


\qecho '## Indexes'
\qecho

\qecho '### Unused (at these instance only)'
\qecho
\i index_poor.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby
    \qecho '### Duplicated'
    \qecho
    \i index_dup.sql
    \qecho

    \qecho '### Foreign Key without indexes'
    \qecho
    \i index_missing_in_fk.sql
    \qecho

    \qecho '### Foreigin Key without index CREATE'
    \qecho
    \i index_missing_in_fk_create.sql
    \qecho
  \endif
\endif

--\qecho '### Tables with many seq scans'
--\qecho
--\i tables_index_missing.sql
--\qecho


\if :svp_pg_90
  \if :svp_not_standby  
    \qecho '## Maintenance'

    \qecho '### Objects with individual adjustments'
    \qecho
    \i object_options.sql 
    \qecho

    \qecho '### Analyze'
    \qecho
    \i autovacuum_analyze.sql
    \qecho

    \qecho '#### Analyze Adjusts'
    \qecho
    \i autovacuum_analyze_adjust.sql
    \qecho

    \qecho '### Vacuum'
    \qecho
    \i autovacuum_vacuum.sql
    \qecho

    \qecho '#### Vacuum Adjusts'
    \qecho
    \i autovacuum_vacuum_adjust.sql
    \qecho

    \qecho '### Vacuum "to prevent wraparound"'
    \qecho
    \i vacuum_wraparound.sql
    \qecho

    \qecho '### Fillfactor'
    \qecho
    \i fillfactor.sql
    \qecho
  \endif
\endif

\qecho '## Functions'
\qecho
\i functions.sql
\qecho

\qecho '## pg_stat_statement'
\qecho

\i statements.sql

\qecho
\qecho END
\pset footer on
\set QUIET off
