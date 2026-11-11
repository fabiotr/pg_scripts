SELECT
    es.stxname AS "Name",
    es.stxnamespace::regnamespace AS "Schema",
    es.stxrelid::regclass AS "Table",
    -- pg_get_statisticsobjdef_columns() only exists from 14
    (SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY array_position(es.stxkeys::int2[], a.attnum))
        FROM pg_attribute a
        WHERE a.attrelid = es.stxrelid AND a.attnum = ANY (es.stxkeys)) AS "Columns",
    CASE WHEN 'd' = ANY(es.stxkind) THEN 'defined' END AS "Ndistinct",
    CASE WHEN 'f' = ANY(es.stxkind) THEN 'defined' END AS "Dependencies",
    CASE WHEN 'm' = ANY(es.stxkind) THEN 'defined' END AS "MCV"
FROM pg_statistic_ext es
ORDER BY 1, 2;

