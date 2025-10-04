SELECT 
 parname AS "Parameter",
 gr.rolname AS "Grantor",
 ge.rolname AS "Grantee",
 privilege_type AS "Privilege",
 is_grantable AS "Grant Opt"
FROM 
 (SELECT parname, (aclexplode(paracl)).*
 FROM pg_parameter_acl) AS acl
 JOIN pg_roles gr ON gr.oid = acl.grantor
 JOIN pg_roles ge ON ge.oid = acl.grantee
ORDER BY 1,2,3,4;
