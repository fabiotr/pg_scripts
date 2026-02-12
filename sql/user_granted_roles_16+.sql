SELECT
	member::regrole   AS "Role",
	roleid::regrole   AS "Granted",
	grantor::regrole  AS "Grantor",
	admin_option      AS "Admin",
	inherit_option    AS "Inherit",
	set_option        AS "SET"
FROM pg_auth_members
WHERE
        member::regrole::text NOT LIKE 'pg_%'      AND
        member::regrole::text NOT LIKE 'cloudsql%' AND
        member::regrole::text NOT LIKE 'rds_%'     AND
        member::regrole::text NOT IN ('postgres')
ORDER BY member::regrole::text, roleid::regrole::text;
