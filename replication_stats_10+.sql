SELECT 
	pid, 
	usename AS "User", 
	application_name AS "App", 
	client_addr AS "Client Addr", 
	to_char(backend_start, 'YYYY-MM-DD HH24:MI:SS') AS "Start",
	to_char(write_lag, 'HH24:MI:SS.MS') AS "Write lag",
	to_char(flush_lag, 'HH24:MI:SS.MS') AS "Flush lag",
	to_char(replay_lag, 'HH24:MI:SS.MS') AS "Replay lag",
	sync_state 
FROM pg_stat_replication
ORDER BY backend_start;
