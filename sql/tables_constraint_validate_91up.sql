SELECT
    'ALTER TABLE ' || 
  quote_ident (n.nspname)   || '.' || 
  quote_ident (c.relname)   || ' VALIDATE CONSTRAINT ' ||  
  quote_ident (con.conname) || ';'
FROM
    pg_constraint con
    JOIN pg_class      c ON c.oid = con.conrelid
    JOIN pg_namespace  n ON n.oid = c.relnamespace
WHERE
    con.convalidated = false AND
    n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname, con.conname;
