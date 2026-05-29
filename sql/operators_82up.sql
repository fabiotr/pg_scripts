SELECT 
    n.nspname as "Schema",
    o.oprname AS "Name",
    CASE WHEN o.oprkind='l' THEN NULL ELSE format_type(o.oprleft,  NULL) END AS "Left arg type",
    CASE WHEN o.oprkind='r' THEN NULL ELSE format_type(o.oprright, NULL) END AS "Right arg type",
    format_type(o.oprresult, NULL) AS "Result type",
    coalesce(obj_description(o.oid, 'pg_operator'), obj_description(o.oprcode, 'pg_proc')) AS "Description"
FROM 
    pg_operator o
    LEFT JOIN pg_namespace n ON n.oid = o.oprnamespace
WHERE 
    n.nspname NOT IN ('pg_catalog', 'information_schema') AND 
    pg_operator_is_visible(o.oid)
ORDER BY 1, 2, 3, 4;
