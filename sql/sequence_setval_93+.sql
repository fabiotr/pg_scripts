--Use this whith logical replication
\t on

--Choose this
SELECT $$SELECT setval('$$ ||  n.nspname || $$.$$ || c.relname || $$',$$ || v || $$);$$ AS sql_setval
FROM 
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace,
    LATERAL nextval(n.nspname || '.' || c.relname) v
WHERE 
            c.relkind IN ('S','')
        AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND pg_table_is_visible(c.oid)
ORDER BY 1;


--Or this, whatever
/*
SELECT 
    $$SELECT setval('$$  || n.nspname || $$.$$ || c.relname || $$',$$ 
        || nextval(n.nspname || '.' || c.relname) 
        || $$);$$ AS sql_setval
FROM 
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE 
            c.relkind = 'S'
        AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND pg_table_is_visible(c.oid)
ORDER BY 1;
*/
\t off
