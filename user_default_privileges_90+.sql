SELECT 
	r.rolname                    AS "Role",
	n.nspname                    AS "Schema",
	CASE defaclobjtype 
		WHEN 'r' THEN 'Table'
		WHEN 'S' THEN 'Sequence'
		WHEN 'f' THEN 'Function'
		WHEN 'T' THEN 'Type'
		ELSE 'Unknow' 
	END                          AS "Type",
	defaclacl                    AS "ACL"
FROM 
	pg_default_acl da
	JOIN pg_roles r ON r.oid = da.defaclrole
	JOIN pg_namespace n ON n.oid = da.defaclnamespace
ORDER BY 1,2,3;
