SELECT 
    n.nspname  AS schema, 
    c.relname  AS table,
    co.conname AS constraint,
    string_agg(a.attname, ', ')  AS column, 
    --string_agg(a.attnum,  ', ')  AS order,
    string_agg(format_type(a.atttypid, a.atttypmod), ', ')  AS data_type, 
    string_agg(coalesce(pg_get_expr(at.adbin, at.adrelid),'null'), ', ') AS default_value
FROM 
    pg_class c 
    JOIN pg_namespace n   ON c.relnamespace = n.oid  
    LEFT JOIN pg_constraint co ON co.connamespace = n.oid AND co.conrelid = c.oid AND co.contype = 'u'
    LEFT JOIN pg_attribute a   ON a.attrelid = c.oid AND a.attnum = ANY (co.conkey)
    LEFT JOIN pg_type t        ON t.oid = a.atttypid
    LEFT JOIN pg_attrdef at    ON at.adrelid = c.oid AND at.adnum = a.attnum
WHERE 
    c.relkind = 'r' AND
    n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
GROUP BY n.nspname, c.relname, co.conname
ORDER BY 1,2,4;
