SELECT 
    oid as "ID",
    pg_get_userbyid(lomowner) as "Owner",
    pg_size_pretty(sum(length(data))) AS "Size",
    obj_description(oid, 'pg_largeobject') as "Description"
FROM 
    pg_largeobject_metadata AS lm
    LEFT JOIN pg_largeobject AS l ON l.loid = lm.oid
GROUP BY lm.oid, lm.lomowner
ORDER BY sum(length(data)) DESC NULLS LAST
LIMIT 10;
