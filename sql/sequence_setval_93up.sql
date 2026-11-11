--Use this with logical replication
\t on

--Choose this
SELECT 'SELECT setval(' || quote_literal(quote_ident(n.nspname) || '.' || quote_ident(c.relname)) || ', ' || v || ');' AS sql_setval
FROM 
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace,
    LATERAL nextval(quote_ident(n.nspname) || '.' || quote_ident(c.relname)) v
WHERE 
            c.relkind IN ('S','')
        AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND c.relpersistence <> 't'
ORDER BY 1;


--Or this, whatever
/*
SELECT 
    'SELECT setval(' || quote_literal(quote_ident(n.nspname) || '.' || quote_ident(c.relname)) || ', '
        || nextval(quote_ident(n.nspname) || '.' || quote_ident(c.relname))
        || ');' AS sql_setval
FROM 
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE 
            c.relkind = 'S'
        AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND c.relpersistence <> 't'
ORDER BY 1;
*/
\t off
