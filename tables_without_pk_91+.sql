SELECT
  n.nspname AS "Schema",
  c.relname AS "Table",
  CASE relkind
    WHEN 'r' THEN 'table'
    WHEN 'v' THEN 'view'
    WHEN 'i' THEN 'index'
    WHEN 'S' THEN 'sequence'
    WHEN 's' THEN 'special'
    WHEN 'f' THEN 'foreign table'
    WHEN 't' THEN 'TOAST table'
    WHEN 'c' THEN 'composite type'
    WHEN 'p' THEN 'partitioned table'
    WHEN 'I' THEN 'partitioned index'
    WHEN 'm' THEN 'materialized view'
  END AS "Type",
  to_char(reltuples,'999G999G999G999') AS "Rows",
  pg_size_pretty(pg_relation_size(c.oid)) AS "Size"
FROM
  pg_class AS c
  JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE
  c.relkind IN ('r','m','p') AND
  c.relpersistence = 'p' AND
  NOT EXISTS (SELECT 1 FROM pg_constraint WHERE contype = 'p' AND conrelid = c.oid) AND
  nspname NOT IN ('pg_catalog','information_schema', 'pg_toast')
ORDER BY pg_relation_size(c.oid) DESC;
