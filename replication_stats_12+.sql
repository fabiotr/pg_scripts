SELECT 
	pid, 
	usename AS "User", 
	application_name AS "App", 
	client_addr AS "Client Addr", 
	backend_start AS "Start", 
	reply_time AS "Last reply", 
	write_lag, 
	flush_lag, 
	replay_lag, 
	sync_state 
FROM pg_stat_replication
ORDER BY backend_start;
