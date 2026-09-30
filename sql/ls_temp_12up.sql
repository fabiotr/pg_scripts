SELECT 
	count(1) AS qt, 
	lpad(pg_size_pretty(sum(size)), 11) AS size, 
	lpad(pg_size_pretty(sum(size)/(CASE WHEN count(1)>0 THEN count(1) ELSE NULL END)), 11) AS avg_size,  
	max(modification) - min(modification) AS range 
FROM pg_ls_tmpdir();
