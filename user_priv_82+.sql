SELECT 
    r.rolname AS role, 
    CASE WHEN r.rolcanlogin         THEN 'X' END AS login,
    CASE WHEN r.rolsuper            THEN 'X' END AS super, 
    CASE WHEN r.rolcreatedb         THEN 'X' END AS c_db, 
    CASE WHEN r.rolcreaterole       THEN 'X' END AS c_role, 
    am.rolname AS member_of 
FROM 
    pg_roles r
    JOIN (SELECT m.member, a.rolname FROM pg_auth_members m JOIN pg_roles a ON (m.roleid = a.oid)) AS am ON am.member = r.oid
WHERE r.rolsuper OR r.rolcreatedb OR r.rolcreaterole
ORDER BY r.rolname, am.rolname
;
