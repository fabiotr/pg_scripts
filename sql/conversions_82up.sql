SELECT 
    n.nspname AS "Schema",
    c.conname AS "Name",
    pg_encoding_to_char(c.conforencoding)   AS "Source",
    pg_encoding_to_char(c.contoencoding)    AS "Destination",
    CASE 
        WHEN c.condefault THEN 'yes'
        ELSE 'no' END                       AS "Default?"
FROM 
    pg_conversion c
    JOIN pg_namespace n ON n.oid = c.connamespace
WHERE
    n.nspname NOT IN ('pg_catalog', 'information_schema') AND 
    pg_conversion_is_visible(c.oid)
ORDER BY 1, 2;
