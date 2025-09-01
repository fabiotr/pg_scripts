SELECT
	rm.rolname     AS "Role",
	rr.rolname     AS "Granted",
	rg.rolname     AS "Grantor",
	admin_option   AS "Admin"
FROM 
	pg_auth_members am
	JOIN pg_roles rm ON rm.oid = am.member
	JOIN pg_roles rr ON rr.oid = am.roleid
	JOIN pg_roles rg ON rg.oid = am.grantor	
ORDER BY 1,2;
