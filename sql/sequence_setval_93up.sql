--Use this with logical replication
\t on

-- Before 10 there is no pg_sequence_last_value(): read each sequence's own
-- last_value (NULL until it is first used, as in the 10up file) with one
-- generated query per sequence, run by \gexec. Never nextval(), which would
-- advance every sequence.
SELECT format('SELECT %L || CASE WHEN is_called THEN last_value END || %L FROM %s',
              'SELECT setval(' || quote_literal(quote_ident(n.nspname) || '.' || quote_ident(c.relname)) || ', ',
              ');',
              quote_ident(n.nspname) || '.' || quote_ident(c.relname))
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
            c.relkind = 'S'
        AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND c.relpersistence <> 't'
        -- only the sequences the user may read; CASE so it only runs on a
        -- sequence: WHERE has no evaluation order
        AND has_schema_privilege(n.oid, 'USAGE')
        AND CASE WHEN c.relkind = 'S' THEN has_sequence_privilege(c.oid, 'SELECT') END
ORDER BY quote_ident(n.nspname) || '.' || quote_ident(c.relname)
\gexec

\t off
