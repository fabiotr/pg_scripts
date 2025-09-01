SELECT 
	evtname     AS "Name", 
	evtevent    AS "Event", 
	r.rolname   AS "Owner", 
	p.proname   AS "Function",  
	CASE evtenabled 
		WHEN 'O' THEN 'Origin'
		WHEN 'D' THEN 'Disabled'
		WHEN 'R' THEN 'Replica'
		WHEN 'A' THEN 'Always'
	END         AS "Enabled",
	evttags     AS "Tags"
FROM 
	pg_event_trigger t
	JOIN pg_roles r ON r.oid = t.evtowner
	JOIN pg_proc p  ON p.oid = t.evtfoid
ORDER BY 1; 
