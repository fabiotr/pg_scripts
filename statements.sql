\set QUIET on
\pset footer off
\timing off
\x off

--Variaveis de configuração */
SELECT 
 	 current_setting('server_version_num')::int >=  80200  AS pg_82
       	,current_setting('server_version_num')::int >=  80300  AS pg_83
       	,current_setting('server_version_num')::int >=  80400  AS pg_84
       	,current_setting('server_version_num')::int >=  90000  AS pg_90
       	,current_setting('server_version_num')::int >=  90100  AS pg_91
       	,current_setting('server_version_num')::int >=  90200  AS pg_92
       	,current_setting('server_version_num')::int >=  90300  AS pg_93
       	,current_setting('server_version_num')::int >=  90400  AS pg_94
       	,current_setting('server_version_num')::int >=  90500  AS pg_95
       	,current_setting('server_version_num')::int >=  90600  AS pg_96
       	,current_setting('server_version_num')::int >= 100000  AS pg_10
       	,current_setting('server_version_num')::int >= 110000  AS pg_11
       	,current_setting('server_version_num')::int >= 120000  AS pg_12
       	,current_setting('server_version_num')::int >= 130000  AS pg_13
       	,current_setting('server_version_num')::int >= 140000  AS pg_14
       	,current_setting('server_version_num')::int >= 150000  AS pg_15
       	,current_setting('server_version_num')::int >= 160000  AS pg_16
	,current_setting('server_version_num')::int >= 170000  AS pg_17
	,current_setting('server_version_num')::int >= 180000  AS pg_18
	,current_setting('server_version') AS server_version
\gset svp_

\qecho
\qecho '## Statements'
\qecho

\qecho '### Statements total'
\qecho
\pset xheader_width 1
\x on
\if :svp_pg_17
  \ir statements_total_17+.sql
\elif :svp_pg_14
  \ir statements_total_14+.sql
\else
  \qecho - pg_stat_statements is not supported on version :svp_server_version
\endif
\x off
\pset xheader_width full

\qecho
\qecho '### Statements resume by total time'
\echo

\if   :svp_pg_18
  \ir statements_resume_18+.sql
\elif :svp_pg_17
  \ir statements_resume_17+.sql
\elif :svp_pg_14
  \ir statements_resume_14+.sql
\else
  \qecho - pg_stat_statements is not supported on version :svp_server_version
\endif

\qecho
\qecho '### Statements by execution time'
\qecho

\if   :svp_pg_17
  \ir statements_time_17+.sql
\elif :svp_pg_14
  \ir statements_time_14+.sql
\elif :svp_pg_13
  \ir statements_time_13+.sql
\elif :svp_pg_95
  \ir statements_time_95+.sql
\elif :svp_pg_94
  \ir statements_time_94+.sql
\elif :svp_pg_84
  \ir statements_time_84+.sql
\else
  \qecho - pg_stat_statements is not supported on version :svp_server_version
\endif

\qecho
\qecho '### Statements by calls'
\qecho

\if :svp_pg_14
  \ir statements_calls_14+.sql
\elif :svp_pg_13
  \ir statements_calls_13+.sql
\elif :svp_pg_95
  \ir statements_calls_95+.sql
\elif :svp_pg_94
  \ir statements_call_94+.sql
\elif :svp_pg_84
  \ir statements_call_84+.sql
\else
  \qecho - pg_stat_statements is not supported on version :svp_server_version
\endif

\qecho
\qecho '### Statements by rows'
\qecho

\if :svp_pg_14
  \ir statements_rows_14+.sql
\elif :svp_pg_13
  \ir statements_rows_13+.sql
\elif :svp_pg_95
  \ir statements_rows_95+.sql
\elif :svp_pg_94
  \ir statements_rows_94+.sql
\elif :svp_pg_84
  \ir statements_rows_84+.sql
\else
  \qecho - pg_stat_statements is not supported on version :svp_server_version
\endif

\qecho
\qecho '### Statements by rows per call'
\qecho

\if :svp_pg_14
  \ir statements_rows_call_14+.sql
\elif :svp_pg_13
  \ir statements_rows_call_13+.sql
\elif :svp_pg_95
  \ir statements_rows_call_95+.sql
\elif :svp_pg_94
  \ir statements_rows_call_94+.sql
\elif :svp_pg_84
  \ir statements_rows_call_84+.sql
\else
  \qecho - pg_stat_statements is not supported on version :svp_server_version
\endif

\qecho
\qecho '### Statements by temp files'
\qecho

\if   :svp_pg_17
  \ir statements_temp_17+.sql
\elif :svp_pg_14
  \ir statements_temp_14+.sql
\elif :svp_pg_13 
  \ir statements_temp_13+.sql
\elif :svp_pg_95
  \ir statements_temp_95+.sql
\elif :svp_pg_94
  \ir statements_temp_94+.sql
\elif :svp_pg_92
  \ir statements_temp_92+.sql
\else
  \qecho - pg_stat_statements with temp data is not supported on version :svp_server_version
\endif

\qecho
\qecho '### Top5 statements by total time with full SQL'
\qecho

\pset xheader_width 1
\x on
\if :svp_pg_13 
  \ir statements_top5_13+.sql
\elif :svp_pg_95
  \ir statements_top5_95+.sql
\elif :svp_pg_94
  \ir statements_top5_94+.sql
\elif :svp_pg_84
  \ir statements_top5_84+.sql
\else
  \qecho - pg_stat_statements is not supported on version :svp_server_version
\endif
\qecho
\x off
\pset xheader_width full
\timing on
\set QUIET off

