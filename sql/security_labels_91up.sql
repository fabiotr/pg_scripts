SELECT
	n.nspname                  AS "Schema",   -- regnamespace only exists from 9.5
	CASE WHEN s.classoid = 'pg_class'::regclass THEN s.objoid::regclass END AS "Table",
    attname                    AS "Column",
	objtype                    AS "Type",
	objname                    AS "Object",
	provider,
	label
FROM 
    pg_seclabels AS s
    LEFT JOIN pg_namespace AS n ON n.oid = s.objnamespace
    LEFT JOIN pg_attribute AS a ON s.classoid = 'pg_class'::regclass AND a.attrelid = s.objoid AND a.attnum = s.objsubid AND s.objsubid <> 0
ORDER BY 1,2,3,4;
