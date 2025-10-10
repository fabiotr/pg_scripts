SELECT 
	relname AS "Table Name",  
    to_char(n_live_tup, '999G999G999G999') AS "Rows",
	pg_size_pretty(pg_relation_size(relid)) AS "Size",
	to_char(seq_scan / reset_days,'999G999G999G999') AS "Seq scans/Day",
	to_char(idx_scan / reset_days,'999G999G999G999') AS "Idx scans/Day",
	trunc(seq_scan::numeric/(greatest(seq_scan + idx_scan,1))*100,1) AS "% Seq scan"
FROM
    pg_stat_user_tables,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days 
    	FROM pg_stat_database 
    	WHERE datname = current_database()) AS r
WHERE 
    n_live_tup > 10000 AND
    seq_scan::numeric/greatest(seq_scan + idx_scan,1) > '0.1'
ORDER BY seq_scan desc
LIMIT 20;
