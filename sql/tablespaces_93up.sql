SELECT
    t.spcname AS "Name",
    pg_get_userbyid(t.spcowner) AS "Owner",
    pg_tablespace_location(t.oid) AS "Location",
    array_to_string(t.spcacl, E'\n') AS "Access privileges",
    t.spcoptions AS "Options",
    CASE WHEN t.oid = (SELECT dattablespace FROM pg_database WHERE datname = current_database())
           OR has_tablespace_privilege(t.oid, 'CREATE')
           OR EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_read_all_stats' AND pg_has_role(oid, 'USAGE'))
         THEN lpad(pg_size_pretty(pg_tablespace_size(t.oid)), 11)
         ELSE lpad('n/a', 11) END AS "Size",
	'' AS "Databases"
FROM pg_tablespace t
WHERE  t.spcname = 'pg_global'
GROUP BY t.spcname, t.spcowner, t.spcacl, t.spcoptions, t.oid
UNION
SELECT
    t.spcname AS "Name",
    pg_get_userbyid(t.spcowner) AS "Owner",
    pg_tablespace_location(t.oid) AS "Location",
    array_to_string(t.spcacl, E'\n') AS "Access privileges",
    t.spcoptions AS "Options",
    CASE WHEN t.oid = (SELECT dattablespace FROM pg_database WHERE datname = current_database())
           OR has_tablespace_privilege(t.oid, 'CREATE')
           OR EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_read_all_stats' AND pg_has_role(oid, 'USAGE'))
         THEN lpad(pg_size_pretty(pg_tablespace_size(t.oid)), 11)
         ELSE lpad('n/a', 11) END AS "Size",
	string_agg(d.datname, ', ') AS "Databases"
FROM 
	pg_tablespace t
	LEFT JOIN LATERAL pg_tablespace_databases(t.oid) AS td(oid) ON TRUE
	LEFT JOIN pg_database d ON d.oid = td.oid AND d.datname NOT IN ('template0', 'template1')
WHERE   
	t.spcname != 'pg_global'
GROUP BY t.spcname, t.spcowner, t.spcacl, t.spcoptions, t.oid
ORDER BY "Name";
