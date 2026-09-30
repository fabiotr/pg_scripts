SELECT 
    oid AS "ID",
    pg_get_userbyid(lomowner) AS "Owner",
    lpad(pg_size_pretty(sum(length(data))), 11) AS "Size",
    obj_description(oid, 'pg_largeobject') AS "Description"
FROM 
    pg_largeobject_metadata AS lm
    LEFT JOIN pg_largeobject AS l ON l.loid = lm.oid
GROUP BY lm.oid, lm.lomowner
ORDER BY sum(length(data)) DESC NULLS LAST
LIMIT 10;
