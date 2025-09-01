SELECT
    t.spcname AS "Name",
    pg_get_userbyid(t.spcowner) AS "Owner",
    t.spclocation AS "Location",
    array_to_string(t.spcacl, E'\n') AS "Access privileges",
    pg_size_pretty(pg_tablespace_size(t.oid)) AS "Size"
FROM pg_tablespace t
ORDER BY "Name";
