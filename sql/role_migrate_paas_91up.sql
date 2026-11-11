
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
	'CREATE ROLE ' || quote_ident(rolname)  || ';' || chr(10) ||
	'ALTER ROLE  ' || quote_ident(rolname)  || 
		CASE rolsuper	    WHEN FALSE THEN '' ELSE ' SUPERUSER '     END ||
		CASE rolinherit     WHEN TRUE  THEN '' ELSE ' NOINHERIT '     END ||
		CASE rolcreaterole  WHEN FALSE THEN '' ELSE ' CREATEROLE '    END ||
		CASE rolcreatedb    WHEN FALSE THEN '' ELSE ' CREATEDB '      END ||
		CASE rolcanlogin    WHEN FALSE THEN '' ELSE ' LOGIN '         END ||
		CASE rolreplication WHEN FALSE THEN '' ELSE ' REPLICATION '   END || 
		CASE rolconnlimit   WHEN -1    THEN '' ELSE ' CONNECTION LIMIT ' || rolconnlimit  END ||
		--CASE WHEN rolpassword IS NULL THEN '' ELSE ' PASSWORD ' || rolpassword END ||
		CASE WHEN rolvaliduntil IS NULL THEN '' ELSE ' VALID UNTIL '  || quote_literal(rolvaliduntil) END || 
		';' AS command
FROM 
	pg_roles AS r 
WHERE 
	rolname NOT IN ('postgres') AND
	rolname NOT LIKE 'pg_%'
ORDER BY rolname;




-- Set roles membership (DISTINCT: from PG 16 the same membership can have several grantors)
SELECT DISTINCT
	'GRANT ' || quote_ident(m.rolname) || 
	' TO ' || quote_ident(r.rolname) || 
	CASE admin_option WHEN FALSE THEN '' ELSE ' WITH ADMIN OPTION' END ||
	';' AS command	
FROM 
	pg_roles r
	JOIN (SELECT rolname, member, admin_option FROM pg_roles r JOIN pg_auth_members m ON r.oid = m.roleid) AS m ON m.member = r.oid
WHERE r.rolname NOT LIKE 'pg_%'
;

-- Set additional role parameters, including the ones for one database (ALTER ROLE ... IN DATABASE).
-- pg_db_role_setting holds "name=value". The list parameters below (GUC_LIST_QUOTE, the same list
-- pg_dumpall uses) hold an identifier list: "quoted" entries may contain commas and "" for a
-- quote, and SET ... FROM CURRENT can store unquoted entries that need quotes (odd-schema).
-- Each entry is decoded and passed as its own literal, so ALTER ROLE quotes it as needed;
-- quote_literal() of the whole value would make it a single element. Unquoted entries of
-- search_path and temp_tablespaces are folded to lower case (ASCII only), as the server reads
-- them. An empty list is stored as "" (or as nothing, by SET ... FROM CURRENT).
-- Settings for a database and every role (ALTER DATABASE ... SET) are not role settings and are left out.
SELECT 
	'ALTER ROLE ' || 
	quote_ident(rolname) || 
	CASE WHEN datname IS NULL THEN '' ELSE ' IN DATABASE ' || quote_ident(datname) END ||
	' SET '        || name || ' TO ' ||
	CASE
		WHEN name NOT IN ('search_path', 'temp_tablespaces', 'local_preload_libraries',
		                  'session_preload_libraries', 'shared_preload_libraries', 'unix_socket_directories')
			THEN quote_literal(value)
		WHEN value IN ('', '""') THEN $$''$$
		ELSE array_to_string(ARRAY(
			SELECT quote_literal(CASE
				WHEN substr(e, 1, 1) = '"' THEN replace(substr(e, 2, length(e) - 2), '""', '"')
				WHEN name IN ('search_path', 'temp_tablespaces')
					THEN translate(e, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')
				ELSE e END)
			FROM (SELECT (regexp_matches(value, '[[:space:]]*("(?:[^"]|"")*"|[^,]*[^,[:space:]])[[:space:]]*(?:,|$)', 'g'))[1] AS e) AS m
			), ', ')
	END || ';' AS command
FROM (
	SELECT rolname, datname, split_part(cfg, '=', 1) AS name, substr(cfg, length(split_part(cfg, '=', 1)) + 2) AS value
	FROM (
		SELECT r.rolname, d.datname, unnest(s.setconfig) AS cfg
		FROM 
			pg_db_role_setting s
			JOIN pg_roles r ON r.oid = s.setrole
			LEFT JOIN pg_database d ON d.oid = s.setdatabase
		) AS c
	) AS r
ORDER BY rolname, datname NULLS FIRST, name;
