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
        -- only the sequences the user may read (pg_sequence_last_value() fails otherwise);
        -- CASE so it only runs on a sequence: WHERE has no evaluation order
        AND has_schema_privilege(n.oid, 'USAGE')
        AND CASE WHEN c.relkind = 'S' THEN has_sequence_privilege(c.oid, 'SELECT, USAGE') END
ORDER BY 1;

\t off
