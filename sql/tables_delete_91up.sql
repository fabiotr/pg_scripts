SELECT 
    schemaname AS "Schema",
    relname AS "Table",  
    lpad(to_char(n_live_tup,            'FM999G999G999G999'),15) AS "Rows",
    lpad(to_char(n_tup_del / reset_days,'FM999G999G999G999'),15) 
        || lpad(' (' || round(100 * n_tup_del / 
        nullif(sum(n_tup_del) OVER (),0),1) || ' %)',9)          AS "DELETE Rows/Day"
FROM
    pg_stat_all_tables,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days 
    	FROM pg_stat_database 
    	WHERE datname = current_database()) AS r
WHERE
    schemaname != 'pg_toast' AND
    n_tup_del > 0
ORDER BY n_tup_del desc
LIMIT 10;

