SELECT slot_name, plugin, slot_type, database, active, active_pid, xmin 
FROM pg_replication_slots 
ORDER BY active, slot_type, slot_name;
