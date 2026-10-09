SELECT
    t.spcname AS "Name",
    pg_get_userbyid(t.spcowner) AS "Owner",
    pg_tablespace_location(t.oid) AS "Location",
    array_to_string(t.spcacl, E'\n') AS "Access privileges",
    t.spcoptions AS "Options",
    CASE WHEN t.oid = (SELECT dattablespace FROM pg_database WHERE datname = current_database())
           OR has_tablespace_privilege(t.oid, 'CREATE')
           OR EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_read_all_stats' AND pg_has_role(oid, 'USAGE'))
         THEN lpad(pg_size_pretty(pg_tablespace_size(t.oid)), 11)
         ELSE lpad('n/a', 11) END AS "Size"
FROM pg_tablespace t
ORDER BY "Name";
