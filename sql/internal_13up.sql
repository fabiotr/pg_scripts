SELECT
  inet_server_addr() AS "Server IP",
  inet_server_port() AS "Server Port",
  date_trunc('second',current_timestamp - pg_postmaster_start_time()) AS "Uptime",
  date_trunc('second',current_timestamp - pg_conf_load_time()) AS "Reload time",
  pg_is_in_recovery()                 AS "Recovery?",
  CASE WHEN :'svp_not_aurora' AND :'svp_recovery' 
    THEN pg_is_wal_replay_paused()
    ELSE NULL END                     AS "Recovery paused?", -- Not supported in AWS Aurora
  current_setting('data_checksums')   AS "Checksum?",
  current_setting('debug_assertions') AS "Debug?",
  pg_size_pretty(pg_size_bytes(current_setting('block_size'))) AS "Block Size",
  pg_size_pretty(pg_size_bytes(current_setting('wal_segment_size'))) AS "Wal Segemnt Size",
  pg_size_pretty(pg_size_bytes(current_setting('segment_size')) * pg_size_bytes(current_setting('block_size'))) AS "Max Segment Size";
