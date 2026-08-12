SELECT 
    n.nspname   AS "Schema",
    r.rolname   AS "Owner",
    l.lanname   AS "Language",
    CASE prokind
        WHEN 'f' THEN 'function'
        WHEN 'p' THEN 'procedure'
        WHEN 'a' THEN 'aggregate'
        WHEN 'w' THEN 'window function'
    END         AS "Type", 
    p.proname   AS "Name",
    format_type(p.prorettype, NULL) AS "Result data type",
    CASE 
        WHEN p.pronargs = 0 THEN CAST('*' AS text)
        ELSE pg_get_function_arguments(p.oid)
    END AS "Argument data types"--,
    --obj_description(p.oid, 'pg_proc') AS "Description"
FROM 
    pg_proc p
    LEFT JOIN pg_roles r ON p.proowner = r.oid
    LEFT JOIN pg_namespace n ON n.oid = p.pronamespace
    LEFT JOIN pg_language l ON l.oid = p.prolang
WHERE 
    n.nspname NOT IN ('pg_catalog', 'information_schema') AND 
    pg_function_is_visible(p.oid) AND
    r.rolname != 'rdsadmin' AND 
    p.oid NOT IN (
	SELECT objid
        FROM
	    pg_catalog.pg_depend d
	    JOIN pg_class c ON c.oid = d.classid
	    JOIN pg_class cc ON cc.oid = d.refclassid
        WHERE
	    c.relname = 'pg_proc' AND
	    cc.relname = 'pg_extension' AND
	    d.deptype = 'e')
ORDER BY 1, 2, 3,4,5;
