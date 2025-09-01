SELECT
    d.datname AS "Database",
    r.rolname AS "Owner",
    pg_encoding_to_char(d.encoding) AS "Encoding",
    pg_size_pretty(pg_database_size(d.datname)) AS "Size",
    drs.setconfig AS "Options"
FROM 
  pg_database d
  JOIN pg_roles r ON r.oid = d.datdba
  LEFT JOIN pg_db_role_setting drs ON d.oid = drs.setdatabase
WHERE 
  d.datname NOT IN ('rdsadmin', 'cloudsqladmin') AND
  NOT d.datistemplate
ORDER BY pg_database_size(d.datname) DESC;
