SELECT
    n.nspname AS "Schema",
    c.relname AS "Object",
    CASE c.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        WHEN 'i' THEN 'INDEX'
        WHEN 'S' THEN 'SEQUENCE'
        WHEN 's' THEN 'special'
        WHEN 'f' THEN 'FOREIGN TABLE'
        WHEN 'p' THEN 'PARTITION TABLE'
        END   AS "Type",
	o.rolname AS "Owner",
    r.rolname AS "Grantee",
    array_to_string(array_agg(acl.privilege_type),', ') AS "Privileges"
FROM
    pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN LATERAL aclexplode(c.relacl) acl ON TRUE
	JOIN pg_roles r ON acl.grantee = r.oid
	JOIN pg_roles o ON c.relowner = o.oid
WHERE
    c.relacl IS NOT NULL AND
    n.nspname NOT IN ('pg_catalog', 'information_schema') AND
    n.nspname !~ '^pg_toast' AND
	o.oid != r.oid
GROUP BY n.nspname, c.relname, c.relkind, o.rolname, r.rolname
ORDER BY n.nspname, c.relname, r.rolname;
