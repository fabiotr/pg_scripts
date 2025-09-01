SELECT current_setting('logging_collector') AS "Collector", current_setting('log_destination') AS "Destination", current_setting('log_directory') AS "Directory", current_setting('log_filename') AS "Filename";

SELECT 
	count(1) AS qt, 
	pg_size_pretty(sum(size)) AS size, 
	pg_size_pretty(sum(size)/(CASE WHEN count(1)>0 THEN count(1) ELSE NULL END)) AS avg_size,  
	max(modification) - min(modification) AS range 
FROM pg_ls_logdir();
