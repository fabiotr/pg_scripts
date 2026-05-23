
-- Script to migrate roles from one cluster to another.
-- Useful when importing a dump into a new cluster.
--
-- WARNING 
-- This script is deprecated since pg_dumpall on PG 11 released the option --no-role-passwords
--
-- Before PG 11, you can use this script:
--
-- If you have access to pg_authid, use pg_dumpall instead:
-- pg_dumpall -r > roles.sql
--
-- If you do not have access to pg_authid, use the pg_roles variant...


-- Create roles
SELECT 
	'CREATE ROLE ' || quote_ident(rolname)  || ';' || CHR(10) ||
	'ALTER ROLE  ' || quote_ident(rolname)  || 
		CASE rolsuper	    WHEN FALSE THEN '' ELSE ' SUPERUSER '     END ||
		CASE rolinherit     WHEN TRUE  THEN '' ELSE ' NOINHERIT '     END ||
		CASE rolcreaterole  WHEN FALSE THEN '' ELSE ' CREATEROLE '    END ||
		CASE rolcreatedb    WHEN FALSE THEN '' ELSE ' CREATEDB '      END ||
		CASE rolcanlogin    WHEN FALSE THEN '' ELSE ' LOGIN '         END ||
		CASE rolreplication WHEN FALSE THEN '' ELSE ' REPLICATION '   END || 
		CASE rolbypassrls   WHEN FALSE THEN '' ELSE ' BYPASSRLS '     END ||
		CASE rolconnlimit   WHEN -1    THEN '' ELSE ' CONNECTION LIMIT ' || rolconnlimit  END ||
		--CASE WHEN rolpassword IS NULL THEN '' ELSE ' PASSWORD ' || rolpassword END ||
		CASE WHEN rolvaliduntil IS NULL THEN '' ELSE ' VALID UNTIL '  || quote_literal(rolvaliduntil) END || 
		';' AS command
FROM 
	pg_roles AS r 
	LEFT JOIN pg_auth_members m ON m.roleid = r.oid
WHERE 
	rolname NOT IN ('postgres') AND
	rolname NOT LIKE 'pg_%'
ORDER BY rolname;




-- Set roles membership
SELECT 
	'GRANT ' || quote_ident(m.rolname) || 
	' TO ' || quote_ident(r.rolname) || 
	CASE admin_option WHEN FALSE THEN '' ELSE ' WITH ADMIN OPTION' END ||
	';' AS command	
FROM 
	pg_roles r
	JOIN (SELECT rolname, member, admin_option FROM pg_roles r JOIN pg_auth_members m ON r.oid = m.roleid) AS m ON m.member = r.oid
WHERE r.rolname NOT LIKE 'pg_%'
;

-- Set additional role parameters
SELECT 
	'ALTER ROLE ' || 
	quote_ident(rolname) || ' ' || 
	'SET '         || replace (unnest(rolconfig), $$=$$, $$ TO '$$) || $$';$$
FROM pg_roles 
WHERE rolconfig IS NOT NULL;

