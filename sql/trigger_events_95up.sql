SELECT 
	evtname             AS "Name", 
	evtevent            AS "Event", 
	evtowner::regrole   AS "Owner", 
	evtfoid::regproc    AS "Function",  
	CASE evtenabled 
		WHEN 'O' THEN 'Origin'
		WHEN 'D' THEN 'Disabled'
		WHEN 'R' THEN 'Replica'
		WHEN 'A' THEN 'Always'
	END                 AS "Enabled",
	evttags             AS "Tags"
FROM pg_event_trigger
ORDER BY 1;
