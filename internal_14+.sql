SELECT 
  inet_server_addr() AS "Server Address", 
  date_trunc('second',current_timestamp - pg_postmaster_start_time()) 	AS "Uptime",
  date_trunc('second',current_timestamp - pg_conf_load_time()) 		AS "Reload time", 
  pg_is_in_recovery() 			AS "Recovery?",
  current_setting('in_hot_standby') 	AS "Hot Standby?", 
  current_setting('data_checksums') 	AS "Checksum?",
  current_setting('debug_assertions') 	AS "Debug?",
  current_setting('huge_pages') 	AS "Huge Pages",
  current_setting('block_size') 	AS "Block Size",
  current_setting('wal_segment_size') 	AS "Wal Segemnt Size",
  current_setting('segment_size') 	AS "Max Segment Size",
  current_setting('server_encoding')	AS "Encoding"
;
