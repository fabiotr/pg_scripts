SELECT
    nspname AS "Name",
    pg_size_pretty(size::bigint) as "Size",
    trunc(size / pg_database_size(current_database()) * 100,2) AS "Size %",
	"Tables",
	"Indexes",
	"P Tables",
	"P Indexes",
	"M Views", 
	"Toast",
	"Sequences",
	"Views",
	"Types",
	"Foreign Tables"
FROM (
    SELECT
        n.nspname,
        SUM(pg_relation_size(c.oid)) AS size,
		count(*) FILTER (WHERE c.relkind = 'r') AS "Tables",
		count(*) FILTER (WHERE c.relkind = 'i') AS "Indexes",
		count(*) FILTER (WHERE c.relkind = 'p') AS "P Tables", 
		count(*) FILTER (WHERE c.relkind = 'I') AS "P Indexes",
		count(*) FILTER (WHERE c.relkind = 'm') AS "M Views",
		count(*) FILTER (WHERE c.relkind = 't') AS "Toast", 
		count(*) FILTER (WHERE c.relkind = 'S') AS "Sequences", 
		count(*) FILTER (WHERE c.relkind = 'v') AS "Views",
		count(*) FILTER (WHERE c.relkind = 'c') AS "Types", 
		count(*) FILTER (WHERE c.relkind = 'f') AS "Foreign Tables"
    FROM 
		pg_class c 
		JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE 
        n.nspname NOT LIKE 'pg_temp_%' AND
	n.nspname NOT LIKE 'pg_toast_temp_%'
    GROUP BY n.nspname) t

ORDER BY size DESC;
