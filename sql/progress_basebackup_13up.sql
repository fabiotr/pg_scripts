SELECT
    pid,    
    now() - a.xact_start AS duration,
    coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
    phase,
    lpad(pg_size_pretty(backup_total), 11)    AS "Size Total",
    lpad(pg_size_pretty(backup_streamed), 11) AS "Size Backuped",
    tablespaces_total               AS "Tablespaces Total",
    tablespaces_streamed            AS "Tablespaces Backuped"
FROM  
    pg_stat_progress_basebackup AS p
    JOIN pg_stat_activity AS a USING (pid)
ORDER BY now() - a.xact_start DESC;

