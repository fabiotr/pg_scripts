SELECT 
    n.nspname AS "Schema",
    p.proname AS "Name",
    format_type(p.prorettype, NULL) AS "Result data type",
    CASE 
        WHEN p.pronargs = 0 THEN CAST('*' AS text)
        ELSE pg_get_function_arguments(p.oid)
    END AS "Argument data types",
    obj_description(p.oid, 'pg_proc') AS "Description"
FROM 
    pg_proc p
    LEFT JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE 
        p.prokind = 'a'
    AND n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
    AND pg_function_is_visible(p.oid)
ORDER BY 1, 2, 4;
