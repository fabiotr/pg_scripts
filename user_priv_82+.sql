SELECT 
    r.rolname AS role, 
    CASE WHEN r.rolcanlogin         THEN 'X' END AS login,
    CASE WHEN r.rolsuper            THEN 'X' END AS super, 
    CASE WHEN r.rolcreatedb         THEN 'X' END AS c_db, 
    CASE WHEN r.rolcreaterole       THEN 'X' END AS c_role, 
    CASE WHEN r.rolreplication      THEN 'X' END AS rep, 
    (SELECT string_agg(a.rolname,', ') FROM pg_auth_members m JOIN pg_roles a ON (m.roleid = a.oid) WHERE m.member = r.oid) AS member_of 
FROM pg_roles r
WHERE r.rolsuper OR r.rolcreatedb OR r.rolcreaterole OR r.rolreplication
ORDER BY rolname
;
