 SELECT 
	rolname AS "User", 
	setconfig AS "Config"
FROM 
	pg_roles r 
	JOIN pg_db_role_setting drs ON r.oid = drs.setrole 
WHERE rolname != 'rdsadmin'
ORDER BY rolname;
