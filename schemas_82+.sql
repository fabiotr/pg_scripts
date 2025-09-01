SELECT 
    schema,
    pg_size_pretty(size::bigint) as "disk space",
    trunc(size / pg_database_size(current_database()) * 100,2) AS "%"
FROM (
    SELECT 
        nspname AS schema,
        SUM(pg_relation_size(pg_class.oid)) AS size
    FROM pg_class JOIN pg_namespace ON relnamespace = pg_namespace.oid
    GROUP BY schema) t
ORDER BY size DESC;

