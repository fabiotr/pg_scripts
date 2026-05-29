SELECT 
    n.nspname AS "Schema",
    t.typname AS "Name",
    format_type(t.typbasetype, t.typtypmod) AS "Type",
    CASE 
        WHEN t.typnotnull 
        THEN 'not null' END AS "Nullable",
    t.typdefault AS "Default",
    array_to_string(ARRAY(
         SELECT pg_get_constraintdef(r.oid, true) 
         FROM pg_constraint r 
         WHERE t.oid = r.contypid), ' ') AS "Check"
FROM 
    pg_type t
    LEFT JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE 
    t.typtype = 'd' AND 
    n.nspname <> 'pg_catalog' AND 
    n.nspname <> 'information_schema' AND 
    pg_type_is_visible(t.oid)
ORDER BY 1, 2;

