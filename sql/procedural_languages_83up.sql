SELECT 
    l.lanname AS "Name",
    pg_get_userbyid(l.lanowner) as "Owner",
    l.lanpltrusted AS "Trusted",
    d.description AS "Description"
FROM 
    pg_language l
    LEFT JOIN pg_description d ON 
        d.classoid = l.tableoid AND 
        d.objoid = l.oid AND 
        d.objsubid = 0
WHERE l.lanplcallfoid != 0
ORDER BY 1;
