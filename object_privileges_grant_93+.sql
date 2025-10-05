SELECT 
    'GRANT ' || array_to_string(array_agg(acl.privilege_type),', ') || ' ON ' || 
        CASE c.relkind
            WHEN 'r' THEN 'TABLE'
            WHEN 'v' THEN 'VIEW'
            WHEN 'm' THEN 'MATERIALIZED VIEW'
            WHEN 'i' THEN 'INDEX'
            WHEN 'S' THEN 'SEQUENCE'
            WHEN 's' THEN 'special'
            WHEN 'f' THEN 'FOREIGN TABLE'
            WHEN 'p' THEN 'PARTITION TABLE'
            END || ' ' ||
    nspname || '.' || relname || ' TO ' || rolname || ';' AS "GRANT COMMAND"
FROM 
    pg_class c, 
    pg_namespace n, 
    pg_roles r,
    LATERAL aclexplode(relacl) acl
WHERE 
    relacl IS NOT NULL AND 
    acl.grantee = r.oid AND 
    c.relnamespace = n.oid AND
    n.nspname <> 'pg_catalog' AND
    n.nspname <> 'information_schema' AND
    n.nspname !~ '^pg_toast'
GROUP BY rolname, nspname, relname, relkind 
ORDER BY rolname, nspname, relname;
