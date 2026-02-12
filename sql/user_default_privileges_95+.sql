SELECT 
    d.defaclrole::regrole            AS "Grantor",
    a.grantee::regrole               AS "Grantee",
    d.defaclnamespace::regnamespace  AS "Schema",
    CASE d.defaclobjtype 
        WHEN 'r' THEN 'Table'
        WHEN 'S' THEN 'Sequence'
        WHEN 'f' THEN 'Function'
        WHEN 'T' THEN 'Type'
        ELSE 'Unknow' 
    END                             AS "Type",
string_agg(a.privilege_type || CASE a.is_grantable WHEN FALSE THEN '' ELSE ' *' END, ', ' ORDER BY a.privilege_type) AS "Privilege"
    --string_agg(a.is_grantable, ', ')
FROM 
    pg_default_acl d,
    LATERAL aclexplode(defaclacl) a
GROUP BY d.defaclrole, a.grantee, d.defaclnamespace, d.defaclobjtype
ORDER BY 1,2,3,4;
