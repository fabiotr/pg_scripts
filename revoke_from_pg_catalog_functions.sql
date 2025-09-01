#When migrating with pg_upgrade to PG12, maybe you will find errors in deprecated functions, related to: 
#"Remove data types abstime, reltime, and tinterval", see https://www.postgresql.org/docs/12/release-12.html

#This SQL revoke all GRANTs on pg_catalog to all users, except postgres

SELECT format('REVOKE ALL ON FUNCTION %s.%s FROM %s;', nspname, oid::regprocedure::text, usename) 
FROM (
    SELECT 
        p.oid,
        n.nspname,
        split_part(unnest(proacl)::text,'=',1) usename
    FROM pg_proc p JOIN pg_namespace n ON n.oid = pronamespace
    WHERE nspname = 'pg_catalog' AND proacl IS NOT NULL) i
WHERE usename NOT IN ('', 'postgres');

