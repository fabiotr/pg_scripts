SELECT
    es.stxname AS "Name",
    es.stxnamespace::regnamespace AS "Schema",
    es.stxrelid::regclass AS "Table",
    pg_get_statisticsobjdef_columns(es.oid) AS "Columns",
    CASE WHEN 'd' = ANY(es.stxkind) THEN 'defined' END AS "Ndistinct",
    CASE WHEN 'f' = ANY(es.stxkind) THEN 'defined' END AS "Dependencies",
    CASE WHEN 'm' = ANY(es.stxkind) THEN 'defined' END AS "MCV"
FROM pg_statistic_ext es
WHERE pg_statistics_obj_is_visible(es.oid)
ORDER BY 1, 2;

