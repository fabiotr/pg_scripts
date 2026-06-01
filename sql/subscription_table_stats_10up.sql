SELECT 
        s.subname AS "Subscription", 
        c.relname AS "Table", 
        CASE sr.srsubstate 
                WHEN 'i' THEN 'initialize'
                WHEN 'd' THEN 'data is being copied'
                WHEN 'f' THEN 'finished table copy'
                WHEN 's' THEN 'synchronized'
                WHEN 'r' THEN 'ready'
                ELSE sr.srsubstate::varchar
        END AS state,
        sr.srsublsn AS lsn
FROM 
        pg_subscription                 AS s
        JOIN pg_subscription_rel        AS sr ON s.oid = sr.srsubid
	JOIN pg_class                   AS c  ON sr.srrelid = c.oid
ORDER BY s.subname, c.relname;
