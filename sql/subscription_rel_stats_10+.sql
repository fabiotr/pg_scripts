SELECT 
        s.subname AS subscription, 
        sr.srrelid::regclass AS table, 
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
        JOIN pg_subscription_rel        AS sr  ON s.oid = sr.srsubid
ORDER BY s.subname, sr.srrelid::regclass;
