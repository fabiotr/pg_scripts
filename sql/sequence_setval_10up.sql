--Use this with logical replication
\t on

SELECT 'SELECT setval(' || quote_literal(quote_ident(n.nspname) || '.' || quote_ident(c.relname)) || ', ' || v || ');' AS sql_setval
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace,
    LATERAL pg_sequence_last_value(c.oid) v
WHERE
            c.relkind IN ('S','')
        AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND c.relpersistence <> 't'
ORDER BY 1;

\t off
