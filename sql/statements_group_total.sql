\set QUIET on
\timing off

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


\x on
\if :svp_pg_18
  \ir statements_group_total_18+.sql
\elif :svp_pg_17
  \ir statements_group_total_17+.sql
\elif :svp_pg_13
  \ir statements_group_total_14+.sql
\else
  \qecho - Not supported on version :svp_server_version
\endif
\x auto
\timing on
\set QUIET off
