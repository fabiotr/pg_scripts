SELECT 
	ol.roname AS "Local",
	os.external_id AS "External",
	remote_lsn,
	local_lsn
FROM 
	pg_replication_origin_status os
	JOIN pg_replication_origin ol ON ol.roident = os.local_id
	JOIN pg_replication_origin oe ON ol.roname  = os.external_id
ORDER BY 1;
