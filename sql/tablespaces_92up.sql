SELECT
    t.spcname AS "Name",
    pg_get_userbyid(t.spcowner) AS "Owner",
    pg_tablespace_location(t.oid) AS "Location",
    array_to_string(t.spcacl, E'\n') AS "Access privileges",
    t.spcoptions AS "Options",
    pg_size_pretty(pg_tablespace_size(t.oid)) AS "Size"
FROM pg_tablespace t
ORDER BY "Name";
