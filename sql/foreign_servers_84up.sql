SELECT
    fs.srvname                           AS "Server",
    fdw.fdwname                          AS "FDW",
    pg_get_userbyid(fs.srvowner)         AS "Owner",
    fs.srvtype                           AS "Type",
    fs.srvversion                        AS "Version",
    array_to_string(fs.srvoptions, ', ') AS "Server Options",
    um.usename                           AS "User",
    array_to_string(um.umoptions, ', ')  AS "User Options"
FROM
    pg_foreign_server fs
    JOIN pg_foreign_data_wrapper fdw ON fdw.oid = fs.srvfdw
    LEFT JOIN pg_user_mappings um ON um.srvname = fs.srvname
ORDER BY fs.srvname, um.usename;
