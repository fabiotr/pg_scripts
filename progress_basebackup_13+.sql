SELECT
    pid,    
    now() - a.xact_start AS duration,
    coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
    phase,
    pg_size_pretty(backup_total)    AS "Size Total",
    pg_size_pretty(backup_streamed) AS "Size Backuped",
    tablespaces_total               AS "Tablespaces Total",
    tablespaces_streamed            AS "Tablespaces Backuped"
FROM  
    pg_stat_progress_basebackup AS p
    JOIN pg_stat_activity AS a using (pid)
ORDER BY now() - a.xact_start DESC;

