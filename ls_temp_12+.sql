SELECT 
	count(1) AS qt, 
	pg_size_pretty(sum(size)) AS size, 
	pg_size_pretty(sum(size)/(CASE WHEN count(1)>0 THEN count(1) ELSE NULL END)) AS avg_size,  
	max(modification) - min(modification) AS range 
FROM pg_ls_tmpdir();
