SELECT
	objnamespace::regnamespace AS "Schema",
	classoid::regclass         AS "Table",
    attname                    AS "Column",
	objtype                    AS "Type",
	objname                    AS "Object",
	provider,
	label
FROM 
    pg_seclabels AS s
    LEFT JOIN pg_attribute AS a ON s.classoid = a.attrelid AND s.classoid = a.attnum
ORDER BY 1,2,3,4;
