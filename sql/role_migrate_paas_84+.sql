-- Script para migrar usuários de um cluster para outro. 
-- Util quando for importar um dump em um novo cluster
--
-- Quando tiver acesso a pg_autid utilize o pg_dumpall:
-- pg_dumpall -r > roles.sql
--
-- Quando não tiver acesso a pg_authid utilizar a versão com a pg_roles (sem senha)


-- Cria usuários
SELECT 
	'CREATE ROLE "' || rolname        || '"' || ';' || CHR(10) ||
	'ALTER ROLE  "' || rolname        || '"' ||
		CASE rolsuper		WHEN FALSE THEN '' ELSE ' SUPERUSER '     END ||
		CASE rolinherit     WHEN TRUE  THEN '' ELSE ' NOINHERIT '     END ||
		CASE rolcreaterole  WHEN FALSE THEN '' ELSE ' CREATEROLE '    END ||
		CASE rolcreatedb    WHEN FALSE THEN '' ELSE ' CREATEDB '      END ||
		CASE rolcanlogin    WHEN FALSE THEN '' ELSE ' LOGIN '         END ||
		CASE rolreplication WHEN FALSE THEN '' ELSE ' REPLICATION '   END || 
		CASE rolbypassrls   WHEN FALSE THEN '' ELSE ' BYPASSRLS '     END ||
		CASE rolconnlimit   WHEN -1 THEN '' ELSE ' CONNECTION LIMIT ' || rolconnlimit  END ||
		--CASE WHEN rolpassword IS NULL THEN '' ELSE ' PASSWORD ' || rolpassword END ||
		CASE WHEN rolvaliduntil IS NULL THEN '' ELSE ' VALID UNTIL '  || rolvaliduntil END || 
		';' AS command
FROM 
	pg_roles AS r 
	LEFT JOIN pg_auth_members m ON m.roleid = r.oid
WHERE 
	rolname NOT IN ('postgres') AND
	rolname NOT LIKE 'pg_%'
ORDER BY rolname;




-- Ajusta pertencimento a outras roles
SELECT 
	'GRANT ' || m.rolname || 
	' TO ' || r.rolname || 
	CASE admin_option WHEN FALSE THEN '' ELSE ' WITH ADMIN OPTION' END ||
	';' AS command	
FROM 
	pg_roles r
	JOIN (SELECT rolname, member, admin_option FROM pg_roles r JOIN pg_auth_members m ON r.oid = m.roleid) AS m ON m.member = r.oid
WHERE r.rolname NOT LIKE 'pg_%'
;

-- Ajusta parâmetros adicionais
SELECT 
	'ALTER ROLE "' || 
	rolname	|| '" ' || 
	'SET '         || replace (unnest(rolconfig), $$=$$, $$ TO '$$) || $$';$$
FROM pg_roles 
WHERE rolconfig IS NOT NULL;

