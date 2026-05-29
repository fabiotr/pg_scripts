SELECT 
    n.nspname as "Schema",
    format_type(t.oid, NULL) AS "Name",
    obj_description(t.oid, 'pg_type') as "Description"
FROM 
    pg_type t
    LEFT JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE 
    (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) AND 
    NOT EXISTS(SELECT 1 FROM pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid) AND 
    n.nspname NOT IN ('pg_catalog', 'information_schema') AND 
    pg_type_is_visible(t.oid)
ORDER BY 1, 2;
