SELECT 
        s.subname AS subscription, 
        s.subpublications AS publication,
        s.subowner::regrole AS owner,
        s.subenabled AS enabled,
        ss.pid,
	ss.leader_pid,
	ss.relid::regclass AS table,
        ss.last_msg_send_time,
        ss.last_msg_receipt_time,
        ss.latest_end_time,
        sss.apply_error_count,
        sss.sync_error_count,
        sss.stats_reset
FROM 
        pg_subscription                      AS s
        LEFT JOIN pg_stat_subscription       AS ss  ON s.oid = ss.subid 
        LEFT JOIN pg_stat_subscription_stats AS sss ON s.oid = ss.subid
ORDER BY s.subname;
