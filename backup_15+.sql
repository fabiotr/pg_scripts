SELECT
    min(times)              AS "Last start",
    max(times)              AS "Last stop",
    max(times) - min(times) AS "Duration",
--    to_char(now() - min(times), 'DD HH24:MI') AS "Time from last start",
    to_char(now() - max(times), 'DD HH24:MI') AS "Time from last stop"
FROM
    ( SELECT
          ((regexp_matches(pg_read_file(waldir || filename), '[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*',
                           'g'))[1])::TIMESTAMP AS times
      FROM
          ( SELECT (pg_ls_dir || '/') AS waldir
            FROM pg_ls_dir('.')
            WHERE pg_ls_dir = 'pg_wal' ) AS get_waldir_name,
          ( SELECT
                pg_ls_dir(( SELECT (pg_ls_dir || '/')
                            FROM pg_ls_dir('.')
                            WHERE pg_ls_dir = 'pg_wal')) AS filename ) AS file_list
      WHERE
          filename LIKE '%.backup' ) AS check_backup_label
;

--SELECT * FROM pg_stat_progress_basebackup;
