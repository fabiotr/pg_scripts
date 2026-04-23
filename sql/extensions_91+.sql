SELECT 
  e.extname          AS "Name", 
  e.extversion       AS "Version", 
  ae.default_version AS "Default version",
  n.nspname          AS "Schema", 
  d.description      AS "Description"
FROM 
  pg_extension e 
  LEFT JOIN pg_namespace n ON n.oid = e.extnamespace 
  LEFT JOIN pg_description d ON d.objoid = e.oid AND d.classoid = 'pg_extension'::regclass 
  LEFT JOIN pg_available_extensions() ae(name, default_version, comment) ON ae.name = e.extname
ORDER BY 1;

