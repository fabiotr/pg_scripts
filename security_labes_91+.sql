SELECT 
	objnamespace::regnamespace AS "Schema",
	classoid::regclass         AS "Table",
	objtype                    AS "Type",
	objname                    AS "Object",
	provider,
	label
FROM pg_seclabels 
ORDER BY 1,2,2;
