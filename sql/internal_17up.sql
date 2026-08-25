SELECT 
  inet_server_addr() AS "Server Address", 
  date_trunc('second',current_timestamp - pg_postmaster_start_time()) 	AS "Uptime",
  date_trunc('second',current_timestamp - pg_conf_load_time()) 		AS "Reload time", 
  pg_is_in_recovery() 			AS "Recovery?",
  CASE WHEN :'svp_not_aurora' AND :'svp_recovery'
    THEN pg_is_wal_replay_paused()
    ELSE NULL END                       AS "Recovery paused?",
  current_setting('in_hot_standby') 	AS "Hot Standby?", 
  current_setting('data_checksums') 	AS "Checksum?",
  current_setting('debug_assertions') 	AS "Debug?",
  current_setting('huge_pages')         AS "Huge Pages",
  current_setting('huge_pages_status')  AS "Huge Page Status",
  pg_size_pretty(pg_size_bytes(current_setting('shared_memory_size'))) 	AS "Shared Memory",
  pg_size_pretty(pg_size_bytes(current_setting('shared_memory_size_in_huge_pages')) * 
    CASE 
      WHEN current_setting('huge_page_size') = '0' THEN 2*1024*1024 
      ELSE pg_size_bytes(current_setting('huge_page_size')) END) 	AS "Shared Huge Pages",
  current_setting('block_size') 	AS "Block Size",
  current_setting('wal_segment_size') 	AS "Wal Segment Size",
  current_setting('segment_size') 	AS "Max Segment Size",
  current_setting('server_encoding')    AS "Encoding";
