SELECT 
	pid, 
	usename AS "User", 
	application_name AS "App", 
	client_addr AS "Client Addr", 
	backend_start AS "Start", 
	sync_state 
FROM pg_stat_replication
ORDER BY backend_start;
