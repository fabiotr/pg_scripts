SELECT 
    schemaname AS "Schema",
    relname    AS "Table",  
    lpad(to_char(n_live_tup,            'FM999G999G999G999'),16) AS "Rows",
    lpad(to_char(n_tup_ins / reset_days,'FM999G999G999G999'),16) 
        || lpad(' (' || round(100 * n_tup_ins / 
        nullif(sum(n_tup_ins) OVER (),0),1) || ' %)',10)          AS "INSERT Rows/Day"
FROM
    pg_stat_all_tables,
    (SELECT EXTRACT(epoch FROM CURRENT_TIMESTAMP - COALESCE(stats_reset, :svp_stats_start_db))::numeric/(60*60*24) AS reset_days 
    	FROM pg_stat_database 
    	WHERE datname = current_database()) AS r
WHERE
    schemaname != 'pg_toast' AND
    n_tup_ins > 0
ORDER BY n_tup_ins DESC
LIMIT 10;

