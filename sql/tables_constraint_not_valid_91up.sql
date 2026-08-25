SELECT
    n.nspname                              AS "Schema",
    c.relname                              AS "Table",
    pg_size_pretty(pg_total_relation_size(c.oid)) AS "Table size",
    con.conname                            AS "Constraint",
    CASE con.contype
        WHEN 'c' THEN 'CHECK'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'x' THEN 'EXCLUSION'
	WHEN 'n' THEN 'NOT NULL'
        ELSE con.contype::text
    END                                     AS "Type",
    pg_get_constraintdef(con.oid)           AS "Definition"
FROM 
    pg_constraint con
    JOIN pg_class      c ON c.oid = con.conrelid
    JOIN pg_namespace  n ON n.oid = c.relnamespace
WHERE 
    con.convalidated = false AND 
    n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname, con.conname;
