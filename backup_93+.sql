SELECT
    min(times)              AS start_time,
    max(times)              AS stop_time,
    max(times) - min(times) AS duration,
    now() - min(times)      AS delta_backup_time_from_start,
    now() - max(times)      AS delta_backup_time_from_finish,
    pg_is_in_backup()
FROM
    ( SELECT
          ((regexp_matches(pg_read_file(waldir || filename), '[0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*',
                           'g'))[1])::TIMESTAMP AS times
      FROM
          ( SELECT (pg_ls_dir || '/') AS waldir
            FROM pg_ls_dir('.')
            WHERE pg_ls_dir IN ('pg_wal', 'pg_xlog') ) AS get_waldir_name,
          ( SELECT
                pg_ls_dir(( SELECT (pg_ls_dir || '/')
                            FROM pg_ls_dir('.')
                            WHERE pg_ls_dir IN ('pg_wal', 'pg_xlog') )) AS filename ) AS file_list
      WHERE
          filename LIKE '%.backup' ) AS check_backup_label
;
