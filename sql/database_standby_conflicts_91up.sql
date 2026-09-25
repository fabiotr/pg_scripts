SELECT
    sd.datname        AS "Database",
    sd.conflicts      AS "Total",
    confl_tablespace  AS "Tablespace",
    confl_lock        AS "Lock",
    confl_deadlock    AS "Deadlock",
    confl_snapshot    AS "Snapshot",
    confl_bufferpin   AS "Bufferpin",
    age(now(),stats_reset) AS "Age" 
FROM 
	pg_database d
        JOIN pg_stat_database sd ON d.oid = sd.datid
	JOIN pg_stat_database_conflicts c ON sd.datid = c.datid
WHERE d.datistemplate IS FALSE
ORDER BY d.datname;
