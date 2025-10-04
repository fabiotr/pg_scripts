SELECT
        rolname AS "User",
        datname AS "Database",
        unnest(setconfig) AS "Config"
FROM
        pg_db_role_setting drs 
        JOIN pg_roles r ON r.oid = drs.setrole
        LEFT JOIN pg_database d ON d.oid = drs.setdatabase
WHERE r.rolname != 'rdsadmin'
ORDER BY rolname, "Config";
