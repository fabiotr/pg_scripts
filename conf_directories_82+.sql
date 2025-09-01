SELECT 
--    category, 
    name AS "conf", 
    current_setting(name) AS value
FROM pg_settings
WHERE name IN ('data_directory','config_file', 'hba_file', 'log_directory', 'ident_file','archive_command', 'unix_socket_directories', 'external_pid_file')
ORDER BY category, name;
