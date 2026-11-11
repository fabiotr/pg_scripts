SELECT
    d.datname                                   AS "Database",
    r.rolname                                   AS "Owner",
    pg_encoding_to_char(d.encoding)             AS "Encoding",
    lpad(pg_size_pretty(pg_database_size(d.datname)), 11) AS "Size",
    array_to_string(drs.setconfig, chr(10))     AS "Options",
    array_to_string(array_agg(p.priv), chr(10)) AS "Privileges"
FROM
  pg_database d
  JOIN pg_roles r ON r.oid = d.datdba
  LEFT JOIN pg_db_role_setting drs ON d.oid = drs.setdatabase
  LEFT JOIN (
    SELECT a.oid, r.rolname || ' (' ||  array_to_string(array_agg((a.acl).privilege_type),', ') || ')' AS priv
    FROM
        (SELECT oid, aclexplode(datacl) AS acl FROM pg_database WHERE datacl IS NOT NULL) a
        JOIN pg_roles r ON r.oid = (a.acl).grantee
    GROUP BY r.rolname, a.oid) AS p ON p.oid = d.oid
WHERE
  d.datname NOT IN ('rdsadmin', 'cloudsqladmin') AND
  NOT d.datistemplate
GROUP BY d.datname, r.rolname, d.encoding, drs.setconfig
ORDER BY pg_database_size(d.datname) DESC;
