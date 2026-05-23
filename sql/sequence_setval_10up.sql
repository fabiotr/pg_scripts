--Use this whith logical replication
\t on

SELECT $$SELECT setval('"$$ ||  n.nspname || $$"."$$ || c.relname || $$"',$$ || v || $$);$$ AS sql_setval
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace,
    LATERAL pg_sequence_last_value($$"$$ || n.nspname || '"."' || c.relname || $$"$$) v
WHERE
            c.relkind IN ('S','')
        AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND pg_table_is_visible(c.oid)
ORDER BY 1;

\t off
