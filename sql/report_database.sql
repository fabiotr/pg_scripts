-- WARNING
-- psql must be >= pg10 to run this script
\ir variables.sql

--Setup
SET client_encoding TO 'UTF8';
SET client_min_messages TO WARNING;
\r
\if :svp_pg_91
  \if :svp_not_standby
    CREATE EXTENSION IF NOT EXISTS pgstattuple;
  \endif
\endif

\pset footer off
\pset null ' - '
\pset border 1
\pset pager off
-- Markdown format
\o | sed 's/+--/\|--/g' | sed 's/--+/--\|/g' | sed 's/^\s\(\s\+\)/\|\1/' | sed 's/-\[ RECORD .*/\| Info \| Value \n\|---\|---\|/'

--Report
\qecho '# 🐘 Report for database :DBNAME'
\qecho '- Date:    ' :svp_date
\qecho '- Host:    ' :HOST
\qecho '- Port:    ' :PORT
\qecho '- Version: ' :SERVER_VERSION_NAME
\qecho

\qecho '# 📌 Index'
\qecho
\qecho [[_TOC_]]
\qecho


\qecho '## 📊 Database stats'
\qecho
\ir database_stats.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby
    \qecho '## 🛠️ Extensions'
    \qecho
    \ir extensions.sql
    \qecho

    \qecho '## 🛡️ Roles'
    \qecho

    \qecho '### Default privileges'
    \qecho
    \ir user_default_privileges.sql
    \qecho
  \endif
\endif

\qecho '### Owner X Connections'
\qecho
\ir user_owners_x_connections.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby
    \qecho '### Row level security'
    \qecho
    \ir security_policies.sql
    \qecho

    \qecho '### Security Labels'
    \qecho
    \ir security_labels.sql
    \qecho
 
  \endif
\endif

\if :svp_pg_14
  \if :svp_master
    \qecho '## Logical Replication slot'
    \qecho
    \ir replication_slots_logical.sql
    \qecho
  \endif
\endif

\if :svp_pg_10
  \if :svp_publication

    \qecho '## 🚀 Logical Replication publications'
    \qecho

    \qecho '### Publications'
    \qecho
    \ir publications.sql
    \qecho

    \qecho '### Schemas in publications'
    \qecho
    \ir publication_schemas.sql
    \qecho

    \qecho '### Tables in publications'
    \qecho
    \ir publication_tables.sql
    \qecho
  \endif

  \if :svp_subscription

    \qecho '## 🚀 Logical Replication subscriptions'
    \qecho

    \qecho '### Subscriptions'
    gqecho
    \ir subscription_stats.sql
    \qecho

    \qecho '### Tables in subscriptions'
    \qecho
    \ir subscription_rel_stats.sql
    \qecho
  \endif
\endif


\qecho '## 📊 I/O'
\qecho

\qecho '### I/O on tables (heap)'
\qecho
\ir io_table_heap.sql
\qecho

\qecho '### I/O on tables (indexes)'
\qecho
\ir io_table_index.sql
\qecho

\qecho '### I/O on tables (toast)'
\qecho
\ir io_table_toast.sql
\qecho

\qecho '### I/O on tables (toast indexes)'
\qecho
\ir io_table_tidx.sql
\qecho

\qecho '### I/O on indexes'
\qecho
\ir io_index.sql
\qecho

\if :svp_not_standby
  \qecho '### I/O on sequences'
  \qecho
  \ir io_sequence.sql
  \qecho
\endif

\qecho '## Database Queries'
\qecho

\qecho '### SELECT stats'
\qecho
\ir tables_select.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby
    \qecho '### DML (INSERT, UPDATE, DELETE) stats'
    \qecho
    \ir tables_changes.sql
    \qecho

    \qecho '### INSERT stats'
    \qecho
    \ir tables_insert.sql
    \qecho

    \qecho '### UPDATE stats'
    \qecho
    \ir tables_update.sql
    \qecho

    \qecho '### DELETE stats'
    \qecho
    \ir tables_delete.sql
    \qecho


    \qecho '## 📂 Tablespaces objects'
    \qecho 
    \ir tablespace_objects.sql
    \qecho

    \qecho '## 📂 Schemas'
    \qecho
    \ir schemas.sql
    \qecho

    \qecho '## 🔍 Views'
    \qecho
    \ir views.sql
    \qecho

    \qecho '## 🔥 Top objects'
    \qecho
    \ir object_size.sql
    \qecho
    
    \qecho '### Procedural Languages'
    \qecho
    \ir procedural_languages.sql
    \qecho

    \qecho '### User Operators'
    \qecho 
    \ir operators.sql
    \qecho

    \qecho '### User Functions'
    \qecho
    \ir functions.sql
    \qecho

    \qecho '### Event Triggers'
    \qecho
    \ir trigger_events.sql
    \qecho

    \qecho '### Access Methods'
    \qecho 
    \ir access_method.sql
    \qecho
    
    \qecho '### Collations'
    \qecho 
    \ir collations.sql
    \qecho

    \qecho '#### User Conversions'
    \qecho
    \ir conversions.sql
    \qecho

    \qecho '### User Data Types'
    \qecho
    \ir data_types.sql
    \qecho
    
    \qecho '### User Domains'
    \qecho
    \ir domains.sql
    \qecho

    \qecho 'Large Objects'
    \qecho
    \ir large_objects.sql
    \qecho

    \qecho '## 📂 Tables'
    \qecho

    \qecho '### Table sizes'
    \qecho
    \ir tables_size.sql
    \qecho

    \qecho '### Tables with TOAST'
    \qecho
    \ir tables_with_toast.sql
    \qecho

    \qecho '### Tables unlogged'
    \qecho
    \ir tables_unlogged.sql
    \qecho
	
	
    \qecho '### Table Triggers'
    \qecho
    \ir trigger_tables.sql
    \qecho
	
    \qecho '### Tables with unused space'
    \qecho
    \ir tables_bloat_approx.sql
    \qecho

    \qecho '### Tables with unused space cleanup'
    \qecho
    \qecho '```sql'
    \ir vacuum_full_or_cluster.sql
    \qecho '```'
    \qecho
	
    \qecho '### Tables without PK'
    \qecho
    \ir tables_without_pk.sql
    \qecho

    \qecho '### Tables without any Index'
    \qecho
    \ir tables_without_index.sql
    \qecho

    \if :svp_under_pg_12
      \qecho '### Tables with OID'
      \qecho
      \ir tables_with_oid.sql
      \qecho
    \endif
	
  \endif
\endif

\qecho '### Tables with seq scan'
\qecho
\ir tables_with_seq_scan.sql
\qecho

\qecho '### Not used tables'
\qecho
\ir tables_not_used.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby

    \qecho '### Partition tables'
    \qecho
    \ir tables_partition.sql
    \qecho

    \qecho '### Materialized Views'
    \qecho
    \ir materialized_views.sql
    \qecho

    \qecho '### Foreign Tables'
    \qecho
    \qecho '```sql'
    \ir tables_foreign.sql
    \qecho '```'
    \qecho
  \endif
\endif


\qecho '## 🔍 Indexes'
\qecho

\qecho '### Unused (at these instance only)'
\qecho
\ir index_poor.sql
\qecho

\if :svp_pg_90
  \if :svp_not_standby
    \qecho '### Duplicated'
    \qecho
    \ir index_dup.sql
    \qecho

    \qecho '### Foreign Key without indexes'
    \qecho
    \ir index_missing_in_fk.sql
    \qecho

    \qecho '### Foreign Key without index CREATE'
    \qecho
    \qecho '```sql'
    \ir index_missing_in_fk_create.sql
    \qecho '```'
    \qecho
  \endif
\endif

--\qecho '### Tables with many seq scans'
--\qecho
--\i tables_index_missing.sql
--\qecho


\if :svp_pg_90
  \if :svp_not_standby  
    \qecho '## 🛠️ Maintenance'

    \qecho '### Objects with individual adjustments'
    \qecho
    \ir object_options.sql 
    \qecho

    \qecho '### Extended Statistics'
    \qecho
    \ir statistic_ext.sql
    \qecho

    \qecho '### Analyze'
    \qecho
    \ir autovacuum_analyze.sql
    \qecho

    \qecho '### Analyze Adjusts'
    \qecho
    \qecho '```sql'
    \ir autovacuum_analyze_adjust.sql
    \qecho '```'
    \qecho

    \qecho '### Vacuum'
    \qecho
    \ir autovacuum_vacuum.sql
    \qecho

    \qecho '### Vacuum Adjusts'
    \qecho
    \qecho '```sql'
    \ir autovacuum_vacuum_adjust.sql
    \qecho '```'
    \qecho

    \qecho '### Vacuum "to prevent wraparound"'
    \qecho
    \ir vacuum_wraparound.sql
    \qecho

    \qecho '### Fillfactor'
    \qecho
    \ir fillfactor.sql
    \qecho
  \endif
\endif

\qecho '## ⚙️ Functions'
\qecho
\ir functions_stats.sql
\qecho

\qecho '## 📊 pg_stat_statement'
\qecho

\ir statements.sql

\qecho
\qecho END
\pset footer on
--RESET client_encoding;
--RESET client_min_messages;
--RESET pg_stat_statements.track;
--\set QUIET off
