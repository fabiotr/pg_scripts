SELECT 
  inet_server_addr() AS "Server Address", 
  date_trunc('second',current_timestamp - pg_postmaster_start_time()) AS "Uptime",
  current_setting('debug_assertions') 	AS "Debug?",
  current_setting('block_size') 	AS "Block Size",
  current_setting('server_encoding')    AS "Encoding"
;
