SELECT 
	pid, status, slot_name, 
	date_trunc('second',last_msg_send_time)    AS send_time, 
	date_trunc('second',last_msg_receipt_time) AS receipt_time, 
	date_trunc('second',latest_end_time) 	   AS end_time
FROM pg_stat_wal_receiver;
