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
    name IN ('max_wal_senders', 'max_replication_slots', 'wal_keep_size', 'max_slot_wal_keep_size', 'idle_replication_slot_timeout',
	     'wal_sender_timeout', 'track_commit_timestamp', 'synchronous_standby_names', 'wal_level')
ORDER BY category, name;
