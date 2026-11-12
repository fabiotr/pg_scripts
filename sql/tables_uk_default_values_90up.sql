SELECT 
    n.nspname  AS schema, 
    c.relname  AS table,
    co.conname AS constraint,
    string_agg(a.attname, ', ')  AS column, 
    string_agg(format_type(a.atttypid, a.atttypmod), ', ')  AS data_type, 
    string_agg(pg_get_expr(ad.adbin, ad.adrelid), ', ') AS default_value
FROM 
    pg_constraint co
    JOIN pg_class c      ON c.oid = co.conrelid
    JOIN pg_namespace n  ON n.oid = c.relnamespace
    JOIN pg_attribute a  ON a.attrelid = c.oid AND a.attnum = ANY (co.conkey)
    JOIN pg_attrdef ad   ON ad.adrelid = c.oid AND ad.adnum = a.attnum
WHERE 
        co.contype = 'u'
    AND c.relkind = 'r'
    AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
GROUP BY n.nspname, c.relname, co.conname
ORDER BY 1,2,4;
