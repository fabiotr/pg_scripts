SELECT amname AS "Name",
  CASE amtype WHEN 'i' THEN 'Index' WHEN 't' THEN 'Table' END AS "Type"
FROM pg_am
ORDER BY 1;

