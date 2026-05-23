SELECT 
        s.subname AS subscription, 
        s.subpublications AS publication,
        s.subowner::regrole AS owner,
        s.subenabled AS enabled,
        ss.pid,
        ss.relid::regclass table,
        ss.last_msg_send_time,
        ss.last_msg_receipt_time,
        ss.latest_end_time
FROM 
        pg_subscription                      AS s
        LEFT JOIN pg_stat_subscription       AS ss  ON s.oid = ss.subid 
ORDER BY s.subname;
