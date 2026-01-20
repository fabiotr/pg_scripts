SELECT
    --category,
    name AS "conf",
    setting AS "value",
    boot_val AS "default",
    unit
FROM pg_settings
WHERE
    source = 'configuration file' AND
    setting != boot_val AND
    name IN ('restore_command', 'archive_cleanup_command', 'recovery_end_command', 
			 'recovery_target', 'recovery_target_name', 'recovery_target_time', 
			 'recovery_target_xid', 'recovery_target_lsn', 'recovery_target_inclusive', 
			 'recovery_target_timeline', 'recovery_target_action')
ORDER BY category, name;
