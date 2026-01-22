SELECT 
--    category, 
    name AS "conf", 
    COALESCE (current_setting(name), boot_val) AS value
FROM pg_settings
WHERE name IN ('data_directory','config_file', 'hba_file', 'log_directory', 'ident_file','archive_command', 'unix_socket_directories', 'external_pid_file', 'extension_control_path')
ORDER BY category, name;
