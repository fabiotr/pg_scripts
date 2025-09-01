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
    name IN ('primary_conninfo', 'primary_slot_name', 'hot_standby', 'max_standby_archive_delay', 'max_standby_streaming_delay', 'wal_receiver_create_temp_slot', 
				'wal_receiver_status_interval', 'hot_standby_feedback', 'wal_receiver_timeout', 'wal_retrieve_retry_interval', 'recovery_min_apply_delay', 
				'max_replication_slots', 'max_logical_replication_workers', 'max_sync_workers_per_subscription', 'max_parallel_apply_workers_per_subscription')
ORDER BY category, name;
